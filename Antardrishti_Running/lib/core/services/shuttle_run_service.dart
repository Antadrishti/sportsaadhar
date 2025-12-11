import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Service for tracking 4x10 meter shuttle run using GPS
class ShuttleRunService {
  // Track positions
  Position? startPosition;
  Position? lastTurnPosition;
  Position? previousPosition;
  List<Position> positionHistory = [];
  
  // Track laps (0-3, total 4 laps)
  int currentLap = 0;
  final int totalLaps = 4;
  
  // Track distance in current lap
  double currentLapDistance = 0.0;
  final double targetLapDistance = 10.0; // 10 meters
  final double distanceTolerance = 3.0; // ±3 meters
  
  // Track direction changes
  int directionChangesDetected = 0;
  final int expectedDirectionChanges = 3; // 3 turns in 4 laps
  
  // GPS accuracy tracking
  List<double> accuracyReadings = [];
  
  // Track time
  DateTime? startTime;
  DateTime? endTime;
  
  // Track if waiting for direction change (lap-based)
  bool waitingForDirectionChange = false;
  
  // Track if waiting for direction change at milestone (10m, 20m, 30m)
  bool waitingForMilestoneDirectionChange = false;
  double? milestoneReached = null; // Track which milestone (10, 20, 30) we're waiting at
  
  // Track which milestones have been passed (10, 20, 30)
  Set<double> passedMilestones = {};
  
  // Track when we started waiting for direction change (for timeout)
  DateTime? directionChangeWaitStartTime;
  
  // Track previous device heading for direction change detection
  double? previousDeviceHeading;
  
  // Track current heading for UI display
  double? currentHeading;
  
  /// Initialize GPS tracking
  Future<bool> initializeGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied');
        return false;
      }

      debugPrint('✅ GPS initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing GPS: $e');
      return false;
    }
  }
  
  /// Check if GPS accuracy is good enough
  Future<GPSAccuracyResult> checkGPSAccuracy() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      
      accuracyReadings.add(position.accuracy);
      
      if (position.accuracy < 5.0) {
        return GPSAccuracyResult(
          isAccurate: true,
          accuracy: position.accuracy,
          message: 'Excellent GPS accuracy',
        );
      } else if (position.accuracy < 10.0) {
        return GPSAccuracyResult(
          isAccurate: true,
          accuracy: position.accuracy,
          message: 'Good GPS accuracy',
        );
      } else if (position.accuracy < 15.0) {
        return GPSAccuracyResult(
          isAccurate: false,
          accuracy: position.accuracy,
          message: 'Moderate GPS accuracy - please wait',
        );
      } else {
        return GPSAccuracyResult(
          isAccurate: false,
          accuracy: position.accuracy,
          message: 'Poor GPS accuracy - move to open area',
        );
      }
    } catch (e) {
      debugPrint('Error checking GPS accuracy: $e');
      return GPSAccuracyResult(
        isAccurate: false,
        accuracy: 999.0,
        message: 'Unable to get GPS signal',
      );
    }
  }
  
  /// Check if user is stationary
  Future<bool> isUserStationary({int durationSeconds = 3}) async {
    List<Position> recentPositions = [];
    
    try {
      for (int i = 0; i < durationSeconds * 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        recentPositions.add(pos);
        
        // Check if we have enough readings
        if (recentPositions.length >= 10) {
          double maxMovement = 0.0;
          for (int j = 1; j < recentPositions.length; j++) {
            double dist = calculateDistance(
              recentPositions[j - 1],
              recentPositions[j],
            );
            if (dist > maxMovement) maxMovement = dist;
          }
          
          // If movement is less than 2 meters, user is stationary
          if (maxMovement < 2.0) {
            debugPrint('✅ User is stationary (max movement: ${maxMovement.toStringAsFixed(2)}m)');
            return true;
          }
        }
      }
      
      debugPrint('❌ User is moving too much');
      return false;
    } catch (e) {
      debugPrint('Error checking if stationary: $e');
      return false;
    }
  }
  
  /// Start the shuttle run
  void startShuttleRun(Position startPos) {
    // Clear any previous data
    positionHistory.clear();
    accuracyReadings.clear();
    
    startPosition = startPos;
    lastTurnPosition = startPos;
    previousPosition = startPos;
    positionHistory.add(startPos);
    accuracyReadings.add(startPos.accuracy);
    currentLap = 0;
    currentLapDistance = 0.0;
    directionChangesDetected = 0;
    startTime = DateTime.now();
    waitingForDirectionChange = false;
    waitingForMilestoneDirectionChange = false;
    milestoneReached = null;
    passedMilestones.clear();
    
    debugPrint('🏃 Shuttle run started at: ${startPos.latitude}, ${startPos.longitude}');
    debugPrint('📍 Start position accuracy: ${startPos.accuracy.toStringAsFixed(1)}m');
  }
  
  /// Update position during shuttle run
  ShuttleRunUpdate updatePosition(Position newPosition) {
    // Update current heading for UI display
    if (newPosition.heading != null && newPosition.heading! >= 0) {
      // Use device heading if available (most accurate)
      currentHeading = newPosition.heading;
    } else if (previousPosition != null) {
      // Calculate heading from GPS if device heading is not available
      try {
        double bearing = Geolocator.bearingBetween(
          previousPosition!.latitude,
          previousPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        // Convert bearing (-180 to 180) to heading (0 to 360)
        currentHeading = bearing >= 0 ? bearing : bearing + 360;
      } catch (e) {
        // Keep previous heading if calculation fails
        debugPrint('Error calculating heading: $e');
      }
    }
    
    if (startPosition == null || previousPosition == null) {
      return ShuttleRunUpdate(
        currentLap: currentLap,
        lapDistance: currentLapDistance,
        totalDistance: currentLap * targetLapDistance + currentLapDistance,
        isLapComplete: false,
        isTestComplete: false,
        directionChanges: directionChangesDetected,
        waitingForDirectionChange: false,
        currentHeading: currentHeading,
      );
    }
    
    // Filter out inaccurate GPS readings (accuracy > 15m) for distance calculation
    // But still allow them for direction change detection
    const double maxAcceptableAccuracy = 15.0;
    bool isAccurateReading = newPosition.accuracy <= maxAcceptableAccuracy;
    
    if (!isAccurateReading) {
      debugPrint('⚠️ Skipping inaccurate GPS reading: accuracy=${newPosition.accuracy.toStringAsFixed(1)}m (max: ${maxAcceptableAccuracy}m)');
      // Still add to history for direction change detection, but don't accumulate distance
      positionHistory.add(newPosition);
      accuracyReadings.add(newPosition.accuracy);
      
      // If we're waiting for direction change, still check it even with poor accuracy
      if (waitingForMilestoneDirectionChange && milestoneReached != null) {
        // PRIMARY METHOD: Check if user moved back toward start/turn point (MOST RELIABLE)
        bool movedBackTowardStart = false;
        if (lastTurnPosition != null && positionHistory.length >= 2) {
          double distanceFromTurnPoint = calculateDistance(newPosition, lastTurnPosition!);
          Position previousPos = positionHistory[positionHistory.length - 2];
          double prevDistance = calculateDistance(previousPos, lastTurnPosition!);
          // Reduced threshold from 3m to 1.5m for more sensitive detection
          if (distanceFromTurnPoint < prevDistance - 1.5) {
            movedBackTowardStart = true;
            debugPrint('📍 User moved back toward turn point - direction change confirmed');
          }
        }
        
        // SECONDARY METHOD: Validate direction change (check in parallel)
        bool directionChanged = false;
        if (positionHistory.length >= 3) {
          directionChanged = validateDirectionChangeStrict(newPosition);
        }
        
        // Resume if REAL direction change is detected from either method
        if (movedBackTowardStart || directionChanged) {
          directionChangesDetected++;
          debugPrint('🔄 Direction change detected at ${milestoneReached}m! Total: $directionChangesDetected');
          
          if (milestoneReached != null) {
            passedMilestones.add(milestoneReached!);
            debugPrint('✅ Added ${milestoneReached}m to passed milestones: $passedMilestones');
          }
          
          // IMPORTANT: Use lastTurnPosition (where they turned) as the reference point
          // This ensures distance is only counted AFTER the direction change
          waitingForMilestoneDirectionChange = false;
          milestoneReached = null;
          directionChangeWaitStartTime = null;
          
          // Set previousPosition to the turn point so distance counting starts from there
          if (lastTurnPosition != null) {
            previousPosition = lastTurnPosition;
            debugPrint('✅ Resuming distance calculation from turn point');
          } else {
            previousPosition = newPosition;
            debugPrint('✅ Resuming distance calculation from current position');
          }
          
          // Update lastTurnPosition to current position for next turn detection
          lastTurnPosition = newPosition;
        }
        previousPosition = newPosition;
        
        double currentTotalDistance = currentLap * targetLapDistance + currentLapDistance;
        return ShuttleRunUpdate(
          currentLap: currentLap,
          lapDistance: currentLapDistance,
          totalDistance: currentTotalDistance,
          isLapComplete: false,
          isTestComplete: false,
          directionChanges: directionChangesDetected,
          gpsAccuracy: newPosition.accuracy,
          waitingForDirectionChange: true,
          currentHeading: currentHeading,
        );
      }
      
      // For inaccurate readings when not waiting for direction change, just update previousPosition
      // but don't accumulate distance
      previousPosition = newPosition;
      double currentTotalDistance = currentLap * targetLapDistance + currentLapDistance;
      return ShuttleRunUpdate(
        currentLap: currentLap,
        lapDistance: currentLapDistance,
        totalDistance: currentTotalDistance,
        isLapComplete: false,
        isTestComplete: false,
        directionChanges: directionChangesDetected,
        gpsAccuracy: newPosition.accuracy,
        waitingForDirectionChange: waitingForMilestoneDirectionChange || waitingForDirectionChange,
        currentHeading: currentHeading,
      );
    }
    
    // Add to history (accurate reading)
    positionHistory.add(newPosition);
    accuracyReadings.add(newPosition.accuracy);
    
    bool isLapComplete = false;
    bool isTestComplete = false;
    
    // Calculate current total distance
    double currentTotalDistance = currentLap * targetLapDistance + currentLapDistance;
    
    // Check if we're waiting for direction change at a milestone (10m, 20m, 30m)
    if (waitingForMilestoneDirectionChange && milestoneReached != null) {
      // We're waiting for direction change - check if it has occurred
      debugPrint('⏳ Waiting for direction change at ${milestoneReached}m milestone...');
      
      // PRIMARY METHOD: Check if user moved back toward start/turn point (MOST RELIABLE)
      // This is the strongest indicator that user has actually turned around
      bool movedBackTowardStart = false;
      if (lastTurnPosition != null && positionHistory.length >= 2) {
        double distanceFromTurnPoint = calculateDistance(newPosition, lastTurnPosition!);
        Position previousPos = positionHistory[positionHistory.length - 2];
        double prevDistance = calculateDistance(previousPos, lastTurnPosition!);
        // Reduced threshold from 3m to 1.5m for more sensitive detection
        // This helps detect direction changes earlier, especially at 10m
        if (distanceFromTurnPoint < prevDistance - 1.5) {
          movedBackTowardStart = true;
          debugPrint('📍 User moved back toward turn point (${prevDistance.toStringAsFixed(2)}m -> ${distanceFromTurnPoint.toStringAsFixed(2)}m) - direction change confirmed');
        } else {
          debugPrint('📍 Still moving away from turn point (${prevDistance.toStringAsFixed(2)}m -> ${distanceFromTurnPoint.toStringAsFixed(2)}m) - waiting for direction change');
        }
      }
      
      // SECONDARY METHOD: Validate direction change using heading, velocity, etc.
      // Check this in parallel with movement detection for better sensitivity
      bool directionChanged = false;
      if (positionHistory.length >= 3) {
        // Check direction change even if movement back isn't detected yet
        // This helps catch direction changes earlier
        directionChanged = validateDirectionChangeStrict(newPosition);
        if (directionChanged) {
          debugPrint('📍 Direction change detected via strict validation (backup method)');
        }
      }
      
      // Resume if we have evidence of direction change from either method
      // Primary: moved back toward turn point (most reliable)
      // Backup: strict direction change validation (works in parallel)
      if (movedBackTowardStart || directionChanged) {
        directionChangesDetected++;
        String reason = movedBackTowardStart ? 'movement back toward turn point' : 'strict validation';
        debugPrint('🔄 Direction change detected at ${milestoneReached}m! Reason: $reason. Total: $directionChangesDetected');
        
        // Add this milestone to passed milestones
        if (milestoneReached != null) {
          passedMilestones.add(milestoneReached!);
          debugPrint('✅ Added ${milestoneReached}m to passed milestones: $passedMilestones');
        }
        
        // Direction change confirmed - resume distance calculation
        // IMPORTANT: Use lastTurnPosition (where they turned) as the reference point for distance calculation
        // This ensures distance is only counted AFTER the direction change, from the turn point
        waitingForMilestoneDirectionChange = false;
        milestoneReached = null;
        directionChangeWaitStartTime = null;
        
        // Set previousPosition to the turn point so distance counting starts from there
        // This ensures we only count distance traveled AFTER the direction change
        final turnPosition = lastTurnPosition;
        if (turnPosition != null) {
          previousPosition = turnPosition;
          debugPrint('✅ Resuming distance calculation from turn point (${turnPosition.latitude.toStringAsFixed(6)}, ${turnPosition.longitude.toStringAsFixed(6)})');
        } else {
          previousPosition = newPosition;
          debugPrint('✅ Resuming distance calculation from current position');
        }
        
        // Update lastTurnPosition to current position for next turn detection
        lastTurnPosition = newPosition;
      } else {
        // Still waiting - don't accumulate distance until user actually changes direction
        previousPosition = newPosition;
        
        return ShuttleRunUpdate(
          currentLap: currentLap,
          lapDistance: currentLapDistance,
          totalDistance: currentTotalDistance, // Keep same distance until direction changes
          isLapComplete: isLapComplete,
          isTestComplete: isTestComplete,
          directionChanges: directionChangesDetected,
          gpsAccuracy: newPosition.accuracy,
          waitingForDirectionChange: true, // Signal to UI that we're waiting
          currentHeading: currentHeading,
        );
      }
    }
    
    // Only accumulate distance if NOT waiting for direction change (lap-based or milestone-based)
    if (!waitingForDirectionChange && !waitingForMilestoneDirectionChange) {
      // Calculate distance from previous position
      double distanceIncrement = calculateDistance(previousPosition!, newPosition);
      
      // Filter out very small movements that are likely GPS noise (< 0.5m)
      // This helps with accuracy by ignoring GPS jitter
      const double minMovementThreshold = 0.5;
      if (distanceIncrement < minMovementThreshold) {
        debugPrint('📍 Ignoring small movement: ${distanceIncrement.toStringAsFixed(2)}m (likely GPS noise)');
        previousPosition = newPosition; // Update position but don't accumulate distance
        double currentTotalDistance = currentLap * targetLapDistance + currentLapDistance;
        return ShuttleRunUpdate(
          currentLap: currentLap,
          lapDistance: currentLapDistance,
          totalDistance: currentTotalDistance,
          isLapComplete: isLapComplete,
          isTestComplete: isTestComplete,
          directionChanges: directionChangesDetected,
          gpsAccuracy: newPosition.accuracy,
          waitingForDirectionChange: false,
          currentHeading: currentHeading,
        );
      }
      
      // Calculate what total distance would be after this increment
      double previousTotalDistance = currentLap * targetLapDistance + currentLapDistance;
      double newTotalDistance = previousTotalDistance + distanceIncrement;
      
      // Check for milestone-based direction change requirements BEFORE adding increment
      // This ensures we stop exactly at the milestone
      if (previousTotalDistance < 10.0 && newTotalDistance >= 10.0 && !passedMilestones.contains(10.0)) {
        // Reached 10m milestone - pause and wait for direction change
        waitingForMilestoneDirectionChange = true;
        milestoneReached = 10.0;
        lastTurnPosition = newPosition;
        directionChangeWaitStartTime = DateTime.now();
        // Accumulate distance up to exactly 10m
        currentLapDistance += (10.0 - previousTotalDistance);
        debugPrint('⏸️ Reached 10m milestone - pausing distance calculation until direction change');
      } else if (previousTotalDistance < 20.0 && newTotalDistance >= 20.0 && passedMilestones.contains(10.0) && !passedMilestones.contains(20.0)) {
        // Reached 20m milestone - pause and wait for direction change
        waitingForMilestoneDirectionChange = true;
        milestoneReached = 20.0;
        lastTurnPosition = newPosition;
        directionChangeWaitStartTime = DateTime.now();
        // Accumulate distance up to exactly 20m
        currentLapDistance += (20.0 - previousTotalDistance);
        debugPrint('⏸️ Reached 20m milestone - pausing distance calculation until direction change');
      } else if (previousTotalDistance < 30.0 && newTotalDistance >= 30.0 && passedMilestones.contains(20.0) && !passedMilestones.contains(30.0)) {
        // Reached 30m milestone - pause and wait for direction change
        waitingForMilestoneDirectionChange = true;
        milestoneReached = 30.0;
        lastTurnPosition = newPosition;
        directionChangeWaitStartTime = DateTime.now();
        // Accumulate distance up to exactly 30m
        currentLapDistance += (30.0 - previousTotalDistance);
        debugPrint('⏸️ Reached 30m milestone - pausing distance calculation until direction change');
      } else if (previousTotalDistance < 40.0 && newTotalDistance >= 40.0 && passedMilestones.contains(30.0)) {
        // Test complete at 40m - allow this increment to be added
        currentLapDistance += distanceIncrement;
        isTestComplete = true;
        endTime = DateTime.now();
        debugPrint('🎉 Test complete at 40m!');
      } else {
        // No milestone reached - accumulate distance normally
        currentLapDistance += distanceIncrement;
      }
      
      // Recalculate total distance
      currentTotalDistance = currentLap * targetLapDistance + currentLapDistance;
      debugPrint('📍 Current total distance: ${currentTotalDistance.toStringAsFixed(2)}m');
      
      // Legacy lap-based logic (kept for compatibility but may not be used)
      // Check if lap is complete (within tolerance)
      if (currentLapDistance >= (targetLapDistance - distanceTolerance)) {
        debugPrint('✅ Lap ${currentLap + 1} completed! Distance: ${currentLapDistance.toStringAsFixed(2)}m');
        
        // Check if this is the last lap
        if (currentLap == totalLaps - 1) {
          // Test complete!
          isTestComplete = true;
          endTime = DateTime.now();
          debugPrint('🎉 Test complete!');
        } else {
          // Lap complete, wait for direction change
          isLapComplete = true;
          waitingForDirectionChange = true;
          lastTurnPosition = newPosition;
          debugPrint('⏳ Waiting for direction change...');
        }
      }
    } else if (waitingForDirectionChange) {
      // Legacy lap-based direction change waiting
      debugPrint('⏳ Still waiting for direction change... Current distance: ${currentLapDistance.toStringAsFixed(2)}m');
      
      // Need at least 3 positions for direction change detection
      if (positionHistory.length >= 3) {
        bool directionChanged = validateDirectionChange(newPosition);
        if (directionChanged) {
          directionChangesDetected++;
          debugPrint('🔄 Direction change detected! Total: $directionChangesDetected');
          
          // Move to next lap - reset everything for fresh start
          currentLap++;
          currentLapDistance = 0.0;
          previousPosition = newPosition; // Reset previous position so counting starts fresh
          waitingForDirectionChange = false;
          debugPrint('✅ Starting lap ${currentLap + 1} - distance reset to 0');
        }
      }
    }
    
    // Always update previous position for next calculation
    previousPosition = newPosition;
    
    return ShuttleRunUpdate(
      currentLap: currentLap,
      lapDistance: currentLapDistance,
      totalDistance: currentTotalDistance,
      isLapComplete: isLapComplete,
      isTestComplete: isTestComplete,
      directionChanges: directionChangesDetected,
      gpsAccuracy: newPosition.accuracy,
      waitingForDirectionChange: waitingForMilestoneDirectionChange || waitingForDirectionChange,
      currentHeading: currentHeading,
    );
  }
  
  /// Validate direction change using multiple methods (including device compass like Google Maps)
  /// This is the standard validation - more lenient for general use
  bool validateDirectionChange(Position currentPosition) {
    // Need at least 2 positions for direction change detection (more lenient)
    if (positionHistory.length < 2) return false;
    
    int historyLength = positionHistory.length;
    
    // Use more recent positions if available
    Position beforeTurn;
    Position atTurn;
    Position afterTurn = currentPosition;
    
    if (historyLength >= 4) {
      // Use positions further back for better detection
      beforeTurn = positionHistory[historyLength - 4];
      atTurn = positionHistory[historyLength - 2];
    } else if (historyLength >= 2) {
      // Use closer positions if we don't have enough history
      beforeTurn = positionHistory[historyLength - 2];
      atTurn = positionHistory[historyLength - 1];
    } else {
      return false;
    }
    
    // Method 1: Check device compass heading (like Google Maps) - MOST ACCURATE
    bool deviceHeadingChanged = false;
    if (currentPosition.heading != null && currentPosition.heading! >= 0) {
      if (previousDeviceHeading != null && previousDeviceHeading! >= 0) {
        double headingDiff = (currentPosition.heading! - previousDeviceHeading!).abs();
        if (headingDiff > 180) headingDiff = 360 - headingDiff;
        
        debugPrint('  Device compass heading: ${previousDeviceHeading!.toStringAsFixed(1)}° -> ${currentPosition.heading!.toStringAsFixed(1)}° (diff: ${headingDiff.toStringAsFixed(1)}°)');
        
        // If device heading changes by ≥90°, that's a strong indicator (like Google Maps)
        if (headingDiff >= 90) {
          deviceHeadingChanged = true;
          debugPrint('  ✅ Direction change detected via device compass (Google Maps style)!');
        }
      }
      previousDeviceHeading = currentPosition.heading;
    }
    
    // Method 2: Check heading change using GPS bearing calculation
    bool headingChanged = detectHeadingChange(beforeTurn, atTurn, afterTurn);
    
    // Method 3: Check velocity reversal
    bool velocityReversed = detectVelocityReversal(beforeTurn, atTurn, afterTurn);
    
    // Method 4: Check if near start/turn point
    bool nearTurnPoint = isNearTurnPoint(currentPosition);
    
    // Method 5: Check if user is moving back (distance decreasing from turn point)
    bool movingBack = false;
    if (lastTurnPosition != null && positionHistory.length >= 2) {
      double currentDist = calculateDistance(currentPosition, lastTurnPosition!);
      Position prevPos = positionHistory[positionHistory.length - 2];
      double prevDist = calculateDistance(prevPos, lastTurnPosition!);
      if (currentDist < prevDist - 1.0) { // Moved at least 1m closer to turn point
        movingBack = true;
      }
    }
    
    debugPrint('Direction change validation:');
    debugPrint('  - Device compass changed: $deviceHeadingChanged (Google Maps style)');
    debugPrint('  - GPS heading changed: $headingChanged');
    debugPrint('  - Velocity reversed: $velocityReversed');
    debugPrint('  - Near turn point: $nearTurnPoint');
    debugPrint('  - Moving back: $movingBack');
    
    // Device compass is most reliable (like Google Maps), so give it priority
    if (deviceHeadingChanged) {
      return true; // Device compass detected change - most accurate
    }
    
    // Otherwise, use other methods
    int confirmations = 0;
    if (headingChanged) confirmations++;
    if (velocityReversed) confirmations++;
    if (nearTurnPoint) confirmations++;
    if (movingBack) confirmations++;
    
    // If any method confirms, accept it
    return confirmations >= 1;
  }
  
  /// Strict validation for direction change - requires multiple strong confirmations
  /// Used when waiting at milestones to prevent false positives
  bool validateDirectionChangeStrict(Position currentPosition) {
    // Need at least 3 positions for strict validation
    if (positionHistory.length < 3) return false;
    
    int historyLength = positionHistory.length;
    
    // Use more recent positions if available
    Position beforeTurn;
    Position atTurn;
    Position afterTurn = currentPosition;
    
    if (historyLength >= 5) {
      // Use positions further back for better detection
      beforeTurn = positionHistory[historyLength - 5];
      atTurn = positionHistory[historyLength - 3];
    } else if (historyLength >= 3) {
      // Use closer positions if we don't have enough history
      beforeTurn = positionHistory[historyLength - 3];
      atTurn = positionHistory[historyLength - 2];
    } else {
      return false;
    }
    
    // Method 1: Check device compass heading - STRICT: require ≥100° change (reduced from 120°)
    bool deviceHeadingChanged = false;
    if (currentPosition.heading != null && currentPosition.heading! >= 0) {
      if (previousDeviceHeading != null && previousDeviceHeading! >= 0) {
        double headingDiff = (currentPosition.heading! - previousDeviceHeading!).abs();
        if (headingDiff > 180) headingDiff = 360 - headingDiff;
        
        debugPrint('  [STRICT] Device compass heading: ${previousDeviceHeading!.toStringAsFixed(1)}° -> ${currentPosition.heading!.toStringAsFixed(1)}° (diff: ${headingDiff.toStringAsFixed(1)}°)');
        
        // STRICT: Require ≥100° change (reduced from 120° for better sensitivity at 10m)
        if (headingDiff >= 100) {
          deviceHeadingChanged = true;
          debugPrint('  ✅ [STRICT] Direction change detected via device compass!');
        }
      }
      // Always update previousDeviceHeading even if validation fails, so we track it properly
      previousDeviceHeading = currentPosition.heading;
    }
    
    // Method 2: Check heading change using GPS bearing - STRICT: require ≥120° change
    bool headingChanged = false;
    try {
      double bearing1 = Geolocator.bearingBetween(
        beforeTurn.latitude, beforeTurn.longitude,
        atTurn.latitude, atTurn.longitude,
      );
      double bearing2 = Geolocator.bearingBetween(
        atTurn.latitude, atTurn.longitude,
        afterTurn.latitude, afterTurn.longitude,
      );
      double diff = (bearing2 - bearing1).abs();
      if (diff > 180) diff = 360 - diff;
      
      debugPrint('  [STRICT] GPS bearing: ${bearing1.toStringAsFixed(1)}° -> ${bearing2.toStringAsFixed(1)}° (diff: ${diff.toStringAsFixed(1)}°)');
      
      // STRICT: Require ≥100° change (reduced from 120° for better sensitivity)
      headingChanged = diff >= 100;
    } catch (e) {
      debugPrint('Error in strict heading detection: $e');
    }
    
    // Method 3: Check velocity reversal - STRICT: require strong negative dot product
    bool velocityReversed = false;
    try {
      double vector1X = atTurn.latitude - beforeTurn.latitude;
      double vector1Y = atTurn.longitude - beforeTurn.longitude;
      double vector2X = afterTurn.latitude - atTurn.latitude;
      double vector2Y = afterTurn.longitude - atTurn.longitude;
      double dotProduct = (vector1X * vector2X) + (vector1Y * vector2Y);
      
      debugPrint('  [STRICT] Dot product: ${dotProduct.toStringAsFixed(4)}');
      
      // STRICT: Require negative dot product (reduced threshold from -0.5 to -0.2 for better sensitivity)
      velocityReversed = dotProduct < -0.2;
    } catch (e) {
      debugPrint('Error in strict velocity reversal: $e');
    }
    
    debugPrint('[STRICT] Direction change validation:');
    debugPrint('  - Device compass changed: $deviceHeadingChanged');
    debugPrint('  - GPS heading changed: $headingChanged');
    debugPrint('  - Velocity reversed: $velocityReversed');
    
    // STRICT: Require device compass change OR (GPS heading change OR velocity reversal)
    // More lenient: accept if device compass changes, OR if GPS heading changes, OR if velocity reverses
    // This ensures better detection especially at 10m milestone
    if (deviceHeadingChanged) {
      return true; // Device compass is most reliable
    }
    
    // Accept if EITHER GPS heading change OR velocity reversal (more lenient than requiring both)
    return headingChanged || velocityReversed;
  }
  
  /// Detect heading change using device compass (like Google Maps) and GPS bearing
  bool detectHeadingChange(Position p1, Position p2, Position p3) {
    try {
      // Method 1: Use device's built-in heading sensor (like Google Maps)
      // This is more accurate than calculating from GPS points
      double? deviceHeading1 = p2.heading;
      double? deviceHeading2 = p3.heading;
      
      if (deviceHeading1 != null && deviceHeading2 != null && 
          deviceHeading1 >= 0 && deviceHeading2 >= 0) {
        // Calculate difference in device heading
        double headingDiff = (deviceHeading2 - deviceHeading1).abs();
        if (headingDiff > 180) headingDiff = 360 - headingDiff;
        
        debugPrint('  Device heading: ${deviceHeading1.toStringAsFixed(1)}° -> ${deviceHeading2.toStringAsFixed(1)}° (diff: ${headingDiff.toStringAsFixed(1)}°)');
        
        // If device heading shows significant change (≥90°), that's a strong indicator
        if (headingDiff >= 90) {
          debugPrint('  ✅ Direction change detected via device compass!');
          return true;
        }
      }
      
      // Method 2: Fallback to GPS-based bearing calculation
      // Calculate bearing from p1 to p2
      double bearing1 = Geolocator.bearingBetween(
        p1.latitude, p1.longitude,
        p2.latitude, p2.longitude,
      );
      
      // Calculate bearing from p2 to p3
      double bearing2 = Geolocator.bearingBetween(
        p2.latitude, p2.longitude,
        p3.latitude, p3.longitude,
      );
      
      // Calculate difference
      double diff = (bearing2 - bearing1).abs();
      if (diff > 180) diff = 360 - diff;
      
      debugPrint('  GPS bearing: ${bearing1.toStringAsFixed(1)}° -> ${bearing2.toStringAsFixed(1)}° (diff: ${diff.toStringAsFixed(1)}°)');
      
      // More lenient: at least 90° turn indicates direction change
      return diff >= 90;
    } catch (e) {
      debugPrint('Error detecting heading change: $e');
      return false;
    }
  }
  
  /// Detect velocity reversal
  bool detectVelocityReversal(Position p1, Position p2, Position p3) {
    try {
      // Calculate velocity vectors
      double vector1X = p2.latitude - p1.latitude;
      double vector1Y = p2.longitude - p1.longitude;
      double vector2X = p3.latitude - p2.latitude;
      double vector2Y = p3.longitude - p2.longitude;
      
      // Calculate dot product (negative means reversed direction)
      double dotProduct = (vector1X * vector2X) + (vector1Y * vector2Y);
      
      debugPrint('  Dot product: ${dotProduct.toStringAsFixed(4)}');
      
      // More lenient: negative or small positive dot product indicates reversal
      return dotProduct < 0.1;
    } catch (e) {
      debugPrint('Error detecting velocity reversal: $e');
      return false;
    }
  }
  
  /// Check if near turn point (start or previous turn)
  bool isNearTurnPoint(Position current) {
    if (lastTurnPosition == null) return false;
    
    double distance = calculateDistance(current, lastTurnPosition!);
    debugPrint('  Distance to turn point: ${distance.toStringAsFixed(2)}m');
    
    // More lenient: within 8 meters of turn point (increased from 5m)
    return distance < 8.0;
  }
  
  /// Calculate distance between two positions using Haversine formula
  double calculateDistance(Position p1, Position p2) {
    return Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
  }
  
  /// Get total elapsed time
  Duration getElapsedTime() {
    if (startTime == null) return Duration.zero;
    DateTime endTimeToUse = endTime ?? DateTime.now();
    return endTimeToUse.difference(startTime!);
  }
  
  /// Get average GPS accuracy
  double getAverageGPSAccuracy() {
    if (accuracyReadings.isEmpty) return 0.0;
    return accuracyReadings.reduce((a, b) => a + b) / accuracyReadings.length;
  }
  
  /// Get current heading (direction of movement) in degrees (0-360)
  /// Returns null if heading is not available
  double? getCurrentHeading() {
    return currentHeading;
  }
  
  /// Get shuttle run result
  ShuttleRunResult getResult() {
    return ShuttleRunResult(
      totalTime: getElapsedTime(),
      totalDistance: currentLap * targetLapDistance + currentLapDistance,
      lapsCompleted: currentLap + (currentLapDistance >= targetLapDistance ? 1 : 0),
      directionChanges: directionChangesDetected,
      averageGpsAccuracy: getAverageGPSAccuracy(),
      averageSpeed: _calculateAverageSpeed(),
    );
  }
  
  /// Calculate average speed
  double _calculateAverageSpeed() {
    Duration elapsed = getElapsedTime();
    if (elapsed.inSeconds == 0) return 0.0;
    
    double totalDistance = currentLap * targetLapDistance + currentLapDistance;
    return totalDistance / elapsed.inSeconds; // m/s
  }
  
  /// Reset service
  void reset() {
    startPosition = null;
    lastTurnPosition = null;
    previousPosition = null;
    positionHistory.clear();
    currentLap = 0;
    currentLapDistance = 0.0;
    directionChangesDetected = 0;
    accuracyReadings.clear();
    startTime = null;
    endTime = null;
    waitingForDirectionChange = false;
    waitingForMilestoneDirectionChange = false;
    milestoneReached = null;
    passedMilestones.clear();
    directionChangeWaitStartTime = null;
    previousDeviceHeading = null;
    currentHeading = null;
  }
}

/// GPS accuracy check result
class GPSAccuracyResult {
  final bool isAccurate;
  final double accuracy;
  final String message;

  GPSAccuracyResult({
    required this.isAccurate,
    required this.accuracy,
    required this.message,
  });
}

/// Shuttle run position update
class ShuttleRunUpdate {
  final int currentLap;
  final double lapDistance;
  final double totalDistance;
  final bool isLapComplete;
  final bool isTestComplete;
  final int directionChanges;
  final double? gpsAccuracy;
  final bool waitingForDirectionChange;
  final double? currentHeading;

  ShuttleRunUpdate({
    required this.currentLap,
    required this.lapDistance,
    required this.totalDistance,
    required this.isLapComplete,
    required this.isTestComplete,
    required this.directionChanges,
    this.gpsAccuracy,
    this.waitingForDirectionChange = false,
    this.currentHeading,
  });
}

/// Shuttle run final result
class ShuttleRunResult {
  final Duration totalTime;
  final double totalDistance;
  final int lapsCompleted;
  final int directionChanges;
  final double averageGpsAccuracy;
  final double averageSpeed;

  ShuttleRunResult({
    required this.totalTime,
    required this.totalDistance,
    required this.lapsCompleted,
    required this.directionChanges,
    required this.averageGpsAccuracy,
    required this.averageSpeed,
  });
  
  /// Get formatted time string
  String get formattedTime {
    int minutes = totalTime.inMinutes;
    int seconds = totalTime.inSeconds % 60;
    int milliseconds = (totalTime.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }
  
  /// Get GPS accuracy rating
  String get gpsAccuracyRating {
    if (averageGpsAccuracy < 5.0) return 'Excellent';
    if (averageGpsAccuracy < 10.0) return 'Good';
    if (averageGpsAccuracy < 15.0) return 'Moderate';
    return 'Poor';
  }
}

