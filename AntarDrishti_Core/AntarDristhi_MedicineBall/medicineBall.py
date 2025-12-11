#!/usr/bin/env python3
"""
Medicine Ball Throw Distance Measurement
=========================================
Measures horizontal throw distance using computer vision.
Uses MediaPipe for pose estimation and HSV for ball tracking.

Usage:
  python throw_distance.py --video throw.mp4 --height 175
  python throw_distance.py --video throw.mp4 --height 175 --origin-x 700
"""

import cv2
import mediapipe as mp
import numpy as np
import argparse
import json
import logging
import sys
import time
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Tuple, List, Callable, Dict

# ═══════════════════════════════════════════════════════════════════════════════
#  LOGGING
# ═══════════════════════════════════════════════════════════════════════════════

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%H:%M:%S"
)
logger = logging.getLogger(__name__)
logging.getLogger("mediapipe").setLevel(logging.WARNING)

# ═══════════════════════════════════════════════════════════════════════════════
#  CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

BALL_COLOR_PRESETS: Dict[str, Tuple[Tuple[int, int, int], Tuple[int, int, int]]] = {
    "orange": ((0, 100, 100), (25, 255, 255)),
    "red":    ((0, 100, 100), (15, 255, 255)),
    "blue":   ((100, 100, 100), (130, 255, 255)),
    "green":  ((35, 100, 100), (85, 255, 255)),
    "yellow": ((20, 100, 100), (35, 255, 255)),
    "brown":  ((5, 50, 50), (25, 150, 200)),      # Medicine ball / tan
}


@dataclass
class Config:
    """Configuration settings."""
    
    # Ball detection - very lenient for distant balls
    hsv_lower: Tuple[int, int, int] = (0, 50, 50)
    hsv_upper: Tuple[int, int, int] = (30, 255, 255)
    min_ball_area: int = 15
    morph_kernel_size: int = 2
    
    # Pose estimation
    pose_model_complexity: int = 1
    pose_min_detection_confidence: float = 0.3
    pose_min_tracking_confidence: float = 0.3
    landmark_visibility_threshold: float = 0.3
    
    # Manual overrides
    manual_scale_cm_per_px: Optional[float] = None
    manual_origin_x: Optional[int] = None
    
    # Visualization
    trajectory_color: Tuple[int, int, int] = (0, 255, 255)
    pose_color: Tuple[int, int, int] = (0, 255, 0)
    ball_marker_color: Tuple[int, int, int] = (0, 0, 255)
    
    @classmethod
    def from_ball_color(cls, color: str) -> "Config":
        if color.lower() not in BALL_COLOR_PRESETS:
            raise ValueError(f"Unknown color: {color}")
        lower, upper = BALL_COLOR_PRESETS[color.lower()]
        return cls(hsv_lower=lower, hsv_upper=upper)


# ═══════════════════════════════════════════════════════════════════════════════
#  DATA CLASSES
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class MeasurementResult:
    """Final measurement result."""
    status: str
    distance_cm: Optional[float] = None
    distance_m: Optional[float] = None
    calibration_scale: Optional[float] = None
    trajectory_points: int = 0
    processing_time_ms: float = 0
    error_message: Optional[str] = None
    
    def to_dict(self) -> dict:
        return {
            "status": self.status,
            "distance_cm": self.distance_cm,
            "distance_m": self.distance_m,
            "calibration_scale": self.calibration_scale,
            "trajectory_points": self.trajectory_points,
            "processing_time_ms": round(self.processing_time_ms, 2),
            "error_message": self.error_message
        }


# ═══════════════════════════════════════════════════════════════════════════════
#  BALL DETECTOR
# ═══════════════════════════════════════════════════════════════════════════════

class BallDetector:
    """Detects colored ball using HSV segmentation."""
    
    def __init__(self, config: Config):
        self.config = config
        self._kernel = np.ones((config.morph_kernel_size, config.morph_kernel_size), np.uint8)
    
    def detect(self, frame: np.ndarray) -> Optional[Tuple[int, int]]:
        """Detect ball position. Returns (x, y) or None."""
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        
        # Color mask
        mask = cv2.inRange(hsv, np.array(self.config.hsv_lower), np.array(self.config.hsv_upper))
        
        # For red/orange, also check upper HSV range
        if self.config.hsv_lower[0] <= 15:
            mask2 = cv2.inRange(hsv, np.array([160, 100, 100]), np.array([180, 255, 255]))
            mask = cv2.bitwise_or(mask, mask2)
        
        # Remove noise
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, self._kernel)
        
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        best_contour = None
        best_area = 0
        
        for contour in contours:
            area = cv2.contourArea(contour)
            if area > self.config.min_ball_area and area > best_area:
                best_area = area
                best_contour = contour
        
        if best_contour is None:
            return None
        
        M = cv2.moments(best_contour)
        if M["m00"] == 0:
            return None
        
        cx = int(M["m10"] / M["m00"])
        cy = int(M["m01"] / M["m00"])
        return (cx, cy)


# ═══════════════════════════════════════════════════════════════════════════════
#  POSE ESTIMATOR
# ═══════════════════════════════════════════════════════════════════════════════

class PoseEstimator:
    """MediaPipe pose estimation for person detection."""
    
    def __init__(self, config: Config):
        self.config = config
        self._mp_pose = mp.solutions.pose
        self._mp_drawing = mp.solutions.drawing_utils
        self._pose = self._mp_pose.Pose(
            static_image_mode=False,
            model_complexity=config.pose_model_complexity,
            min_detection_confidence=config.pose_min_detection_confidence,
            min_tracking_confidence=config.pose_min_tracking_confidence
        )
    
    def get_person_x(self, frame: np.ndarray) -> Optional[Tuple[int, float]]:
        """Get person's X position and pixel height. Returns (x, height) or None."""
        height, width = frame.shape[:2]
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = self._pose.process(rgb)
        
        if not result.pose_landmarks:
            return None
        
        landmarks = result.pose_landmarks.landmark
        vis = self.config.landmark_visibility_threshold
        
        # Try to get person position from various landmarks
        left_hip = landmarks[self._mp_pose.PoseLandmark.LEFT_HIP]
        right_hip = landmarks[self._mp_pose.PoseLandmark.RIGHT_HIP]
        left_ankle = landmarks[self._mp_pose.PoseLandmark.LEFT_ANKLE]
        right_ankle = landmarks[self._mp_pose.PoseLandmark.RIGHT_ANKLE]
        nose = landmarks[self._mp_pose.PoseLandmark.NOSE]
        
        # Get X position from hips or ankles
        person_x = None
        if left_hip.visibility >= vis and right_hip.visibility >= vis:
            person_x = int(((left_hip.x + right_hip.x) / 2) * width)
        elif left_ankle.visibility >= vis and right_ankle.visibility >= vis:
            person_x = int(((left_ankle.x + right_ankle.x) / 2) * width)
        
        if person_x is None:
            return None
        
        # Try to get full height (nose to ankle)
        pixel_height = None
        if nose.visibility >= vis:
            nose_y = nose.y * height
            # Try ankles first for more accurate height
            if left_ankle.visibility >= vis and right_ankle.visibility >= vis:
                ankle_y = ((left_ankle.y + right_ankle.y) / 2) * height
                pixel_height = abs(ankle_y - nose_y)
            elif left_hip.visibility >= vis and right_hip.visibility >= vis:
                # Fall back to torso estimation
                hip_y = ((left_hip.y + right_hip.y) / 2) * height
                torso_height = abs(hip_y - nose_y)
                pixel_height = torso_height / 0.35  # Torso ~35% of height
        
        return (person_x, pixel_height)
    
    def draw_landmarks(self, frame: np.ndarray) -> np.ndarray:
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = self._pose.process(rgb)
        if result.pose_landmarks:
            self._mp_drawing.draw_landmarks(
                frame, result.pose_landmarks, self._mp_pose.POSE_CONNECTIONS)
        return frame


# ═══════════════════════════════════════════════════════════════════════════════
#  VISUALIZER
# ═══════════════════════════════════════════════════════════════════════════════

class Visualizer:
    """Handles drawing on frames."""
    
    def __init__(self, config: Config):
        self.config = config
        self._font = cv2.FONT_HERSHEY_SIMPLEX
    
    def draw_trajectory(self, frame: np.ndarray, points: List[Tuple[int, int]]) -> np.ndarray:
        if len(points) < 2:
            return frame
        for i in range(1, len(points)):
            cv2.line(frame, points[i-1], points[i], self.config.trajectory_color, 2)
        for p in points:
            cv2.circle(frame, p, 4, self.config.trajectory_color, -1)
        return frame
    
    def draw_ball_marker(self, frame: np.ndarray, pos: Tuple[int, int]) -> np.ndarray:
        cv2.circle(frame, pos, 12, self.config.ball_marker_color, 2)
        cv2.circle(frame, pos, 4, self.config.ball_marker_color, -1)
        return frame
    
    def draw_reference_line(self, frame: np.ndarray, x: int) -> np.ndarray:
        h = frame.shape[0]
        cv2.line(frame, (x, 0), (x, h), self.config.pose_color, 2)
        cv2.putText(frame, "Origin", (x + 5, 30), self._font, 0.6, self.config.pose_color, 2)
        return frame
    
    def draw_distance(self, frame: np.ndarray, x1: int, x2: int, dist_cm: float) -> np.ndarray:
        h = frame.shape[0]
        y = h - 50
        cv2.line(frame, (x1, y), (x2, y), (255, 255, 0), 2)
        cv2.circle(frame, (x1, y), 6, (0, 0, 255), -1)
        cv2.circle(frame, (x2, y), 6, (0, 255, 0), -1)
        mid = (x1 + x2) // 2
        cv2.putText(frame, f"{dist_cm:.1f} cm", (mid - 50, y - 15), self._font, 0.7, (255, 255, 0), 2)
        return frame
    
    def draw_status(self, frame: np.ndarray, info: dict) -> np.ndarray:
        overlay = frame.copy()
        cv2.rectangle(overlay, (10, 10), (320, 90), (0, 0, 0), -1)
        cv2.addWeighted(overlay, 0.6, frame, 0.4, 0, frame)
        y = 35
        for k, v in info.items():
            cv2.putText(frame, f"{k}: {v}", (20, y), self._font, 0.5, (255, 255, 255), 1)
            y += 20
        return frame
    
    def draw_result(self, frame: np.ndarray, result: dict) -> np.ndarray:
        dark = (frame * 0.4).astype(np.uint8)
        h, w = frame.shape[:2]
        cx, cy = w // 2, h // 2
        bw, bh = 420, 220
        x1, y1 = cx - bw//2, cy - bh//2
        
        cv2.rectangle(dark, (x1, y1), (x1+bw, y1+bh), (40, 40, 40), -1)
        cv2.rectangle(dark, (x1, y1), (x1+bw, y1+bh), (255, 255, 255), 2)
        
        status_color = (0, 255, 0) if result.get("status") == "VALID" else (0, 0, 255)
        cv2.putText(dark, f"Result: {result.get('status', 'UNKNOWN')}", (x1+20, y1+45), 
                   self._font, 0.9, status_color, 2)
        
        if result.get("distance_cm"):
            cv2.putText(dark, f"Distance: {result['distance_cm']:.1f} cm", (x1+20, y1+100), 
                       self._font, 1.1, (255, 255, 255), 2)
            cv2.putText(dark, f"({result['distance_cm']/100:.2f} m)", (x1+20, y1+140), 
                       self._font, 0.8, (200, 200, 200), 1)
        
        cv2.putText(dark, "Press any key to close", (x1+100, y1+190), self._font, 0.5, (150, 150, 150), 1)
        return dark


# ═══════════════════════════════════════════════════════════════════════════════
#  MAIN MEASURER
# ═══════════════════════════════════════════════════════════════════════════════

class ThrowDistanceMeasurer:
    """Main class for measuring throw distance."""
    
    def __init__(self, config: Optional[Config] = None):
        self.config = config or Config()
        self._ball_detector = BallDetector(self.config)
        self._pose_estimator = PoseEstimator(self.config)
        self._visualizer = Visualizer(self.config)
    
    def process_video(self, video_path: str, athlete_height_cm: float, show_preview: bool = True) -> MeasurementResult:
        """Process video and measure throw distance."""
        start_time = time.time()
        
        if not Path(video_path).exists():
            return MeasurementResult(status="ERROR", error_message=f"Video not found: {video_path}")
        
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            return MeasurementResult(status="ERROR", error_message="Cannot open video")
        
        try:
            result = self._process(cap, athlete_height_cm, show_preview)
            result.processing_time_ms = (time.time() - start_time) * 1000
            return result
        finally:
            cap.release()
            if show_preview:
                cv2.destroyAllWindows()
    
    def _process(self, cap: cv2.VideoCapture, athlete_height_cm: float, show_preview: bool) -> MeasurementResult:
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        logger.info(f"📹 Video: {width}x{height} @ {fps:.1f}fps, {total_frames} frames")
        
        # Initialize
        scale: Optional[float] = self.config.manual_scale_cm_per_px
        all_balls: List[Tuple[int, int, int]] = []  # (x, y, frame)
        person_x_hint: Optional[int] = None  # Person position from pose detection
        
        if scale:
            logger.info(f"📐 Using manual scale: {scale:.4f} cm/px")
        
        frame_count = 0
        last_frame = None
        
        # Process all frames
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            frame_count += 1
            last_frame = frame.copy()
            
            # Try to detect person for scale and position
            if scale is None or person_x_hint is None:
                pose_result = self._pose_estimator.get_person_x(frame)
                if pose_result:
                    px, ph = pose_result
                    if person_x_hint is None:
                        person_x_hint = px
                        logger.info(f"👤 Person detected at x={person_x_hint}")
                    if scale is None and ph and ph > 30:
                        candidate_scale = athlete_height_cm / ph
                        if 0.2 <= candidate_scale <= 1.5:
                            scale = candidate_scale
                            logger.info(f"📐 Scale calculated: {scale:.4f} cm/px (person height: {ph:.0f}px)")
            
            # Detect ball
            ball_pos = self._ball_detector.detect(frame)
            if ball_pos:
                all_balls.append((ball_pos[0], ball_pos[1], frame_count))
            
            # Visualize
            if ball_pos:
                frame = self._visualizer.draw_ball_marker(frame, ball_pos)
            if len(all_balls) > 1:
                frame = self._visualizer.draw_trajectory(frame, [(b[0], b[1]) for b in all_balls])
            
            # Find dynamic origin (where throw actually starts)
            display_origin = None
            if len(all_balls) >= 5:
                for i in range(len(all_balls) - 3):
                    x1 = all_balls[i][0]
                    x2 = all_balls[i + 2][0]
                    if abs(x2 - x1) > 15:
                        display_origin = all_balls[max(0, i-1)][0]
                        break
                if display_origin is None:
                    display_origin = all_balls[0][0]
                frame = self._visualizer.draw_reference_line(frame, display_origin)
            
            frame = self._visualizer.draw_status(frame, {
                "Frame": f"{frame_count}/{total_frames}",
                "Ball Points": len(all_balls),
                "Origin": f"x={display_origin}" if display_origin else "Detecting..."
            })
            
            if show_preview:
                cv2.imshow("Throw Distance", frame)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    return MeasurementResult(status="CANCELLED")
        
        # Analyze results
        logger.info(f"📊 Collected {len(all_balls)} ball positions")
        
        if len(all_balls) < 3:
            return MeasurementResult(
                status="INVALID",
                trajectory_points=len(all_balls),
                error_message="Not enough ball detections. Adjust ball color settings."
            )
        
        # Find the throw origin using multiple strategies
        origin_x = all_balls[0][0]
        
        # Strategy 1: If we have person position from pose, find ball near person
        if person_x_hint is not None:
            # Find ball detections closest to person (within 200px)
            balls_near_person = [(x, y, f) for x, y, f in all_balls if abs(x - person_x_hint) < 200]
            if balls_near_person:
                # Use the first detection near person as origin
                origin_x = balls_near_person[0][0]
                logger.info(f"📍 Origin (near person at x={person_x_hint}): x={origin_x}")
            else:
                # No balls near person - filter static objects
                from collections import defaultdict
                position_counts = defaultdict(int)
                for x, y, f in all_balls:
                    bucket = (x // 50) * 50
                    position_counts[bucket] += 1
                
                static_bucket = max(position_counts, key=position_counts.get) if position_counts else 0
                static_count = position_counts[static_bucket]
                
                if static_count > len(all_balls) * 0.4:
                    filtered_balls = [(x, y, f) for x, y, f in all_balls if abs(x - static_bucket - 25) > 75]
                    logger.info(f"🔍 Filtered {len(all_balls) - len(filtered_balls)} static detections")
                    if len(filtered_balls) >= 3:
                        all_balls = filtered_balls
                        origin_x = all_balls[0][0]
                
                # Look for movement start
                for i in range(len(all_balls) - 3):
                    x1 = all_balls[i][0]
                    x2 = all_balls[i + 2][0]
                    if abs(x2 - x1) > 20:
                        origin_x = all_balls[max(0, i-1)][0]
                        break
                
                logger.info(f"📍 Origin (throw start): x={origin_x}")
        else:
            # No person detected - use first ball position
            logger.info(f"📍 Origin (first detection): x={origin_x}")
        
        # Override with manual origin if provided
        if self.config.manual_origin_x:
            origin_x = self.config.manual_origin_x
            logger.info(f"📍 Using manual origin: x={origin_x}")
        
        # Estimate scale if not determined
        if scale is None:
            # For outdoor scenes, assume ~0.5 cm/px as reasonable default
            # This means 1000 pixels = 5 meters, typical for a throw
            scale = 0.5
            logger.warning(f"⚠️ Scale estimated (default): {scale:.4f} cm/px")
        
        # Find landing: lowest point (highest y in image coords)
        landing_idx = max(range(len(all_balls)), key=lambda i: all_balls[i][1])
        landing_x, landing_y, landing_frame = all_balls[landing_idx]
        
        logger.info(f"🎯 Landing at ({landing_x}, {landing_y}) frame {landing_frame}")
        
        # Calculate distance from origin (first ball position) to landing
        pixel_dist = abs(landing_x - origin_x)
        dist_cm = pixel_dist * scale
        
        logger.info(f"📏 Distance: {pixel_dist}px = {dist_cm:.1f}cm (origin x={origin_x}, landing x={landing_x})")
        
        # Show result
        if show_preview and last_frame is not None:
            result_frame = self._visualizer.draw_trajectory(last_frame, [(b[0], b[1]) for b in all_balls])
            result_frame = self._visualizer.draw_reference_line(result_frame, origin_x)
            result_frame = self._visualizer.draw_ball_marker(result_frame, (landing_x, landing_y))
            result_frame = self._visualizer.draw_distance(result_frame, origin_x, landing_x, dist_cm)
            result_frame = self._visualizer.draw_result(result_frame, {
                "status": "VALID",
                "distance_cm": round(dist_cm, 2)
            })
            cv2.imshow("Throw Distance", result_frame)
            cv2.waitKey(0)
        
        return MeasurementResult(
            status="VALID",
            distance_cm=round(dist_cm, 2),
            distance_m=round(dist_cm / 100, 3),
            calibration_scale=scale,
            trajectory_points=len(all_balls)
        )


# ═══════════════════════════════════════════════════════════════════════════════
#  CLI
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="Measure throw distance from video")
    parser.add_argument("--video", "-v", required=True, help="Video file path")
    parser.add_argument("--height", "-H", type=float, required=True, dest="height_cm", help="Athlete height in cm")
    parser.add_argument("--ball-color", "-c", choices=["orange", "red", "blue", "green", "yellow", "brown"], 
                       default="orange", help="Ball color")
    parser.add_argument("--origin-x", type=int, help="Manual person X position (pixels)")
    parser.add_argument("--scale", type=float, help="Manual scale (cm/pixel)")
    parser.add_argument("--no-preview", action="store_true", help="Disable preview")
    parser.add_argument("--output", "-o", help="Output JSON file")
    
    args = parser.parse_args()
    
    # Create config
    config = Config.from_ball_color(args.ball_color)
    if args.origin_x:
        config.manual_origin_x = args.origin_x
    if args.scale:
        config.manual_scale_cm_per_px = args.scale
    
    # Print banner
    print("\n" + "═" * 50)
    print("  THROW DISTANCE MEASUREMENT")
    print("═" * 50)
    print(f"  Video:  {args.video}")
    print(f"  Height: {args.height_cm} cm")
    print(f"  Ball:   {args.ball_color}")
    if args.origin_x:
        print(f"  Origin: x={args.origin_x}")
    print("═" * 50 + "\n")
    
    # Run
    measurer = ThrowDistanceMeasurer(config)
    result = measurer.process_video(args.video, args.height_cm, not args.no_preview)
    
    # Display result
    print("\n" + "═" * 50)
    print("  RESULT")
    print("═" * 50)
    if result.status == "VALID":
        print(f"  ✅ Status:   {result.status}")
        print(f"  📏 Distance: {result.distance_cm:.1f} cm ({result.distance_m:.2f} m)")
        print(f"  📊 Points:   {result.trajectory_points}")
    else:
        print(f"  ❌ Status:   {result.status}")
        if result.error_message:
            print(f"  ⚠️  Error:    {result.error_message}")
    print("═" * 50 + "\n")
    
    # Save output
    if args.output:
        with open(args.output, "w") as f:
            json.dump(result.to_dict(), f, indent=2)
        print(f"💾 Saved to: {args.output}\n")
    
    print("JSON Output:")
    print(json.dumps(result.to_dict(), indent=2))
    
    return 0 if result.status == "VALID" else 1


if __name__ == "__main__":
    sys.exit(main())