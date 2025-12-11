from fastapi import FastAPI, APIRouter, Query, HTTPException, Response
from fastapi.responses import StreamingResponse
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Dict, Any, Union
import uuid
from datetime import datetime, timezone, timedelta
from bson import ObjectId
import json
import io
import csv

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app
app = FastAPI(title="SAI Admin Dashboard API")

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============ MODELS ============

class VerificationAction(BaseModel):
    action: str  # verify, flag, unverify
    note: Optional[str] = None
    adminId: str = "SAI_ADMIN_001"

class QueryFilter(BaseModel):
    filters: Optional[Dict[str, Any]] = {}
    sort: Optional[List[Dict[str, str]]] = []
    groupBy: Optional[List[str]] = []
    aggregate: Optional[List[Dict[str, Any]]] = []
    page: int = 1
    limit: int = 25

class AuditLogEntry(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    adminId: str
    action: str
    targetId: str
    targetType: str
    before: Optional[Dict[str, Any]] = None
    after: Optional[Dict[str, Any]] = None
    note: Optional[str] = None
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

# ============ HELPER FUNCTIONS ============

def serialize_doc(doc: dict) -> dict:
    """Convert MongoDB document to JSON-serializable format"""
    if doc is None:
        return None
    result = {}
    for key, value in doc.items():
        if key == '_id':
            # Handle grouped _id which can be a dict
            if isinstance(value, dict):
                result['_id'] = value
                result['id'] = str(value)
            else:
                result['id'] = str(value)
        elif isinstance(value, ObjectId):
            result[key] = str(value)
        elif isinstance(value, datetime):
            result[key] = value.isoformat()
        elif isinstance(value, dict):
            result[key] = serialize_doc(value)
        elif isinstance(value, list):
            result[key] = [serialize_doc(v) if isinstance(v, dict) else (str(v) if isinstance(v, ObjectId) else v) for v in value]
        else:
            result[key] = value
    return result

async def log_audit(admin_id: str, action: str, target_id: str, target_type: str, before: dict = None, after: dict = None, note: str = None):
    """Log an admin action to audit collection"""
    audit_entry = {
        "id": str(uuid.uuid4()),
        "adminId": admin_id,
        "action": action,
        "targetId": target_id,
        "targetType": target_type,
        "before": before,
        "after": after,
        "note": note,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
    await db.admin_audit.insert_one(audit_entry)
    return audit_entry

def build_mongo_filter(filters: Dict[str, Any]) -> Dict[str, Any]:
    """Convert UI filters to MongoDB query format"""
    mongo_filter = {}
    
    for key, value in filters.items():
        if key == '$or' or key == '$and':
            mongo_filter[key] = value
        elif isinstance(value, dict):
            # Handle operators like $gt, $lt, $gte, $lte
            mongo_filter[key] = value
        elif isinstance(value, list):
            # Handle $in queries
            mongo_filter[key] = {"$in": value}
        else:
            mongo_filter[key] = value
    
    return mongo_filter

# ============ API ENDPOINTS ============

@api_router.get("/")
async def root():
    return {"message": "SAI Admin Dashboard API", "version": "1.0.0"}

# Dashboard KPIs
@api_router.get("/admin/dashboard")
async def get_dashboard_stats():
    """Get dashboard KPIs and statistics"""
    try:
        # Total candidates
        total_candidates = await db.users.count_documents({})
        
        # Total tests
        total_tests = await db.testresults.count_documents({})
        
        # Verification stats (using verification field we'll add)
        verified_count = await db.users.count_documents({"verification.status": "verified"})
        flagged_count = await db.users.count_documents({"verification.status": "flagged"})
        pending_count = total_candidates - verified_count - flagged_count
        
        # Average scores by category
        category_pipeline = [
            {"$group": {
                "_id": None,
                "avgStrength": {"$avg": "$categoryScores.strength"},
                "avgEndurance": {"$avg": "$categoryScores.endurance"},
                "avgFlexibility": {"$avg": "$categoryScores.flexibility"},
                "avgAgility": {"$avg": "$categoryScores.agility"},
                "avgSpeed": {"$avg": "$categoryScores.speed"}
            }}
        ]
        category_stats = await db.users.aggregate(category_pipeline).to_list(1)
        
        # Tests by state
        state_pipeline = [
            {"$group": {
                "_id": "$state",
                "count": {"$sum": 1},
                "avgXP": {"$avg": "$currentXP"}
            }},
            {"$sort": {"count": -1}},
            {"$limit": 10}
        ]
        state_stats = await db.users.aggregate(state_pipeline).to_list(10)
        
        # Recent activity
        recent_pipeline = [
            {"$sort": {"createdAt": -1}},
            {"$limit": 5}
        ]
        recent_users = await db.users.aggregate(recent_pipeline).to_list(5)
        
        # Test type distribution
        test_type_pipeline = [
            {"$group": {
                "_id": "$testType",
                "count": {"$sum": 1},
                "avgScore": {"$avg": "$comparisonScore"}
            }},
            {"$sort": {"count": -1}}
        ]
        test_type_stats = await db.testresults.aggregate(test_type_pipeline).to_list(20)
        
        # Performance rating distribution
        rating_pipeline = [
            {"$group": {
                "_id": "$performanceRating",
                "count": {"$sum": 1}
            }}
        ]
        rating_stats = await db.testresults.aggregate(rating_pipeline).to_list(10)
        
        return {
            "totalCandidates": total_candidates,
            "totalTests": total_tests,
            "verification": {
                "verified": verified_count,
                "flagged": flagged_count,
                "pending": pending_count,
                "verifiedRate": round(verified_count / total_candidates * 100, 1) if total_candidates > 0 else 0,
                "flaggedRate": round(flagged_count / total_candidates * 100, 1) if total_candidates > 0 else 0
            },
            "categoryAverages": category_stats[0] if category_stats else {},
            "candidatesByState": [{"state": s["_id"], "count": s["count"], "avgXP": round(s["avgXP"] or 0, 1)} for s in state_stats],
            "testTypeDistribution": [{"testType": t["_id"], "count": t["count"], "avgScore": round(t["avgScore"] or 0, 1)} for t in test_type_stats],
            "performanceRatings": {r["_id"]: r["count"] for r in rating_stats if r["_id"]},
            "recentCandidates": [serialize_doc(u) for u in recent_users]
        }
    except Exception as e:
        logger.error(f"Dashboard stats error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Candidates List
@api_router.get("/admin/candidates")
async def get_candidates(
    page: int = Query(1, ge=1),
    limit: int = Query(25, ge=1, le=100),
    sort: Optional[str] = None,
    state: Optional[str] = None,
    city: Optional[str] = None,
    gender: Optional[str] = None,
    minAge: Optional[int] = None,
    maxAge: Optional[int] = None,
    minXP: Optional[int] = None,
    maxXP: Optional[int] = None,
    verificationStatus: Optional[str] = None,
    search: Optional[str] = None,
    testType: Optional[str] = None
):
    """Get paginated list of candidates with filters"""
    try:
        # Build filter
        filter_query = {}
        
        if state:
            filter_query["state"] = state
        if city:
            filter_query["city"] = city
        if gender:
            filter_query["gender"] = gender
        if minAge is not None or maxAge is not None:
            filter_query["age"] = {}
            if minAge is not None:
                filter_query["age"]["$gte"] = minAge
            if maxAge is not None:
                filter_query["age"]["$lte"] = maxAge
        if minXP is not None or maxXP is not None:
            filter_query["currentXP"] = {}
            if minXP is not None:
                filter_query["currentXP"]["$gte"] = minXP
            if maxXP is not None:
                filter_query["currentXP"]["$lte"] = maxXP
        if verificationStatus:
            if verificationStatus == "pending":
                filter_query["$or"] = [
                    {"verification.status": {"$exists": False}},
                    {"verification.status": "pending"}
                ]
            else:
                filter_query["verification.status"] = verificationStatus
        if search:
            filter_query["$or"] = [
                {"name": {"$regex": search, "$options": "i"}},
                {"email": {"$regex": search, "$options": "i"}},
                {"aadhaarNumber": {"$regex": search, "$options": "i"}}
            ]
        
        # Build sort
        sort_dict = {}
        if sort:
            parts = sort.split(":")
            field = parts[0]
            direction = -1 if len(parts) > 1 and parts[1] == "desc" else 1
            sort_dict[field] = direction
        else:
            sort_dict["createdAt"] = -1
        
        # Get total count
        total = await db.users.count_documents(filter_query)
        
        # Get paginated results
        skip = (page - 1) * limit
        cursor = db.users.find(filter_query).sort(list(sort_dict.items())).skip(skip).limit(limit)
        candidates = await cursor.to_list(limit)
        
        return {
            "total": total,
            "page": page,
            "limit": limit,
            "totalPages": (total + limit - 1) // limit,
            "results": [serialize_doc(c) for c in candidates],
            "appliedFilters": filter_query
        }
    except Exception as e:
        logger.error(f"Get candidates error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Single Candidate Profile
@api_router.get("/admin/candidates/{candidate_id}")
async def get_candidate(candidate_id: str):
    """Get full candidate profile with test history"""
    try:
        # Find candidate
        candidate_oid = ObjectId(candidate_id)
        candidate = await db.users.find_one({"_id": candidate_oid})
        if not candidate:
            raise HTTPException(status_code=404, detail="Candidate not found")
        
        # Get test results for this candidate (userId is stored as ObjectId)
        test_results = await db.testresults.find(
            {"userId": candidate_oid}
        ).sort("date", -1).to_list(100)
        
        # Get activity logs (try both ObjectId and string formats)
        activity_logs = await db.activitylogs.find(
            {"$or": [{"userId": candidate_oid}, {"userId": candidate_id}]}
        ).sort("activityDate", -1).to_list(50)
        
        return {
            "candidate": serialize_doc(candidate),
            "testResults": [serialize_doc(t) for t in test_results],
            "activityLogs": [serialize_doc(a) for a in activity_logs]
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Get candidate error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Test Results
@api_router.get("/admin/test-results")
async def get_test_results(
    page: int = Query(1, ge=1),
    limit: int = Query(25, ge=1, le=100),
    sort: Optional[str] = None,
    testType: Optional[str] = None,
    testName: Optional[str] = None,
    category: Optional[str] = None,
    performanceRating: Optional[str] = None,
    gender: Optional[str] = None,
    ageGroup: Optional[str] = None,
    minScore: Optional[float] = None,
    maxScore: Optional[float] = None,
    startDate: Optional[str] = None,
    endDate: Optional[str] = None,
    userId: Optional[str] = None,
    search: Optional[str] = None
):
    """Get paginated test results with filters and user names"""
    try:
        filter_query = {}
        
        if testType:
            filter_query["testType"] = testType
        if testName:
            filter_query["testName"] = testName
        if category:
            filter_query["category"] = category
        if performanceRating:
            filter_query["performanceRating"] = performanceRating
        if gender:
            filter_query["gender"] = gender
        if ageGroup:
            filter_query["ageGroup"] = ageGroup
        if userId:
            filter_query["userId"] = userId
        if minScore is not None or maxScore is not None:
            filter_query["comparisonScore"] = {}
            if minScore is not None:
                filter_query["comparisonScore"]["$gte"] = minScore
            if maxScore is not None:
                filter_query["comparisonScore"]["$lte"] = maxScore
        if startDate or endDate:
            filter_query["date"] = {}
            if startDate:
                filter_query["date"]["$gte"] = startDate
            if endDate:
                filter_query["date"]["$lte"] = endDate
        
        # Build sort
        sort_dict = {}
        if sort:
            parts = sort.split(":")
            field = parts[0]
            direction = -1 if len(parts) > 1 and parts[1] == "desc" else 1
            sort_dict[field] = direction
        else:
            sort_dict["date"] = -1
        
        total = await db.testresults.count_documents(filter_query)
        skip = (page - 1) * limit
        cursor = db.testresults.find(filter_query).sort(list(sort_dict.items())).skip(skip).limit(limit)
        results = await cursor.to_list(limit)
        
        # Fetch user names for each test result
        user_ids = list(set([r.get("userId") for r in results if r.get("userId")]))
        user_map = {}
        
        for uid in user_ids:
            try:
                user = await db.users.find_one({"_id": ObjectId(uid)})
                if user:
                    user_map[str(uid)] = {
                        "name": user.get("name", "Unknown"),
                        "state": user.get("state", ""),
                        "city": user.get("city", "")
                    }
            except:
                pass
        
        # Add user info to results
        enriched_results = []
        for r in results:
            doc = serialize_doc(r)
            uid = str(r.get("userId", ""))
            if uid in user_map:
                doc["userName"] = user_map[uid]["name"]
                doc["userState"] = user_map[uid]["state"]
                doc["userCity"] = user_map[uid]["city"]
            else:
                doc["userName"] = "Unknown"
                doc["userState"] = ""
                doc["userCity"] = ""
            enriched_results.append(doc)
        
        # Filter by search (name) if provided - post-filter since we enriched
        if search:
            search_lower = search.lower()
            enriched_results = [r for r in enriched_results if search_lower in r.get("userName", "").lower()]
            total = len(enriched_results)
        
        return {
            "total": total,
            "page": page,
            "limit": limit,
            "totalPages": (total + limit - 1) // limit,
            "results": enriched_results,
            "appliedFilters": filter_query
        }
    except Exception as e:
        logger.error(f"Get test results error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Advanced Query
@api_router.post("/admin/query")
async def execute_query(query: QueryFilter):
    """Execute complex queries with grouping and aggregation"""
    try:
        pipeline = []
        
        # Combined test filters: testFilter.TestName.metric format
        # Each test filter specifies both the test name AND the metric to filter
        # Example: "testFilter.800m Run.speed": {"$gt": 2} means testName="800m Run" AND speed>2
        test_filters = []  # List of {testName: str, metric: str, condition: dict}
        
        # Work with a copy of filters to avoid Pydantic immutability issues
        filters_copy = dict(query.filters) if query.filters else {}
        
        # Helper to extract testFilter fields from a dict
        def extract_test_filters(d):
            extracted = []
            keys_to_remove = []
            for key, value in d.items():
                if key.startswith("testFilter."):
                    # Parse testFilter.TestName.metric
                    parts = key.split(".", 2)  # ["testFilter", "TestName", "metric"]
                    if len(parts) == 3:
                        test_name = parts[1]
                        metric = parts[2]
                        extracted.append({"testName": test_name, "metric": metric, "condition": value})
                        keys_to_remove.append(key)
            for key in keys_to_remove:
                del d[key]
            return extracted
        
        # Extract from top-level filters
        test_filters.extend(extract_test_filters(filters_copy))
        
        # Extract from nested $and/$or conditions
        for key in ["$and", "$or"]:
            if key in filters_copy:
                new_conditions = []
                for cond in filters_copy[key]:
                    if isinstance(cond, dict):
                        extracted = extract_test_filters(cond)
                        test_filters.extend(extracted)
                        # If condition still has other fields, keep it
                        if cond:
                            new_conditions.append(cond)
                    else:
                        new_conditions.append(cond)
                if new_conditions:
                    filters_copy[key] = new_conditions
                elif key in filters_copy:
                    del filters_copy[key]
        
        logger.info(f"Extracted test filters: {test_filters}")
        
        # If test filters exist, get user IDs from testresults first
        # Each test filter is independent (different test types can be combined with AND)
        all_user_id_sets = []
        enrichment_test_names = []  # Track which tests to enrich results with
        
        if test_filters:
            for tf in test_filters:
                test_name = tf["testName"]
                metric = tf["metric"]
                condition = tf["condition"]
                
                # Build query for this test filter
                test_query = {"testName": test_name}
                if isinstance(condition, dict):
                    test_query[metric] = condition
                else:
                    test_query[metric] = condition
                
                logger.info(f"Test query for {test_name}.{metric}: {test_query}")
                test_cursor = db.testresults.find(test_query, {"userId": 1})
                test_results = await test_cursor.to_list(10000)
                
                # Get unique user IDs for this filter
                user_id_set = set()
                for r in test_results:
                    uid = r.get("userId")
                    if uid:
                        user_id_set.add(str(uid))
                
                all_user_id_sets.append(user_id_set)
                enrichment_test_names.append(test_name)
                logger.info(f"Found {len(user_id_set)} users for {test_name}.{metric}")
            
            # Intersect all user ID sets (AND logic - user must match ALL test filters)
            if all_user_id_sets:
                final_user_ids_str = set.intersection(*all_user_id_sets)
                
                if not final_user_ids_str:
                    # No users match all criteria
                    return {
                        "total": 0,
                        "page": query.page,
                        "limit": query.limit,
                        "totalPages": 0,
                        "results": [],
                        "grouped": len(query.groupBy) > 0,
                        "testFilters": [{"testName": tf["testName"], "metric": tf["metric"]} for tf in test_filters]
                    }
                
                # Convert string IDs back to ObjectId for MongoDB query
                from bson import ObjectId
                user_ids = [ObjectId(uid) for uid in final_user_ids_str]
                
                # Add user ID filter to pipeline
                pipeline.append({"$match": {"_id": {"$in": user_ids}}})
        
        # Match stage for other filters
        if filters_copy:
            mongo_filter = build_mongo_filter(filters_copy)
            if mongo_filter:
                pipeline.append({"$match": mongo_filter})
        
        # Group stage
        if query.groupBy:
            group_id = {}
            for field in query.groupBy:
                key = field.replace(".", "_")
                group_id[key] = f"${field}"
            
            group_stage = {
                "_id": group_id,
                "count": {"$sum": 1}
            }
            
            # Add aggregate operations
            if query.aggregate:
                for agg in query.aggregate:
                    op = agg.get("op", "count")
                    field = agg.get("field", "")
                    alias = agg.get("alias", f"{op}_{field.replace('.', '_')}")
                    
                    if op == "avg":
                        group_stage[alias] = {"$avg": f"${field}"}
                    elif op == "sum":
                        group_stage[alias] = {"$sum": f"${field}"}
                    elif op == "min":
                        group_stage[alias] = {"$min": f"${field}"}
                    elif op == "max":
                        group_stage[alias] = {"$max": f"${field}"}
            
            pipeline.append({"$group": group_stage})
            pipeline.append({"$sort": {"count": -1}})
        else:
            # Sort stage (for non-grouped queries)
            # Skip sort for test metric fields - they'll be sorted after enrichment
            test_metric_fields = ["timeTaken", "speed", "distance"]
            if query.sort:
                sort_dict = {}
                for s in query.sort:
                    sort_field = s.get("field", "_id")
                    # Check if it's a testFilter field (testFilter.TestName.metric)
                    is_test_metric_sort = False
                    if sort_field.startswith("testFilter."):
                        is_test_metric_sort = True
                    elif sort_field in test_metric_fields:
                        is_test_metric_sort = True
                    
                    # Skip test metric fields in MongoDB sort - will sort after enrichment
                    if not is_test_metric_sort:
                        direction = -1 if s.get("dir") == "desc" else 1
                        sort_dict[sort_field] = direction
                if sort_dict:
                    pipeline.append({"$sort": sort_dict})
        
        # Pagination
        skip = (query.page - 1) * query.limit
        
        # Count total before pagination
        count_pipeline = pipeline.copy()
        count_pipeline.append({"$count": "total"})
        count_result = await db.users.aggregate(count_pipeline).to_list(1)
        total = count_result[0]["total"] if count_result else 0
        
        # Add pagination
        pipeline.append({"$skip": skip})
        pipeline.append({"$limit": query.limit})
        
        results = await db.users.aggregate(pipeline).to_list(query.limit)
        
        # If filtering by test metrics, enrich results with test data
        serialized_results = [serialize_doc(r) for r in results]
        
        # Check if we need enrichment - either for test filters OR for sorting by test metrics
        sort_test_name = None
        if query.sort:
            for s in query.sort:
                sort_field = s.get("field", "")
                if sort_field.startswith("testFilter."):
                    parts = sort_field.split(".", 2)
                    if len(parts) == 3:
                        sort_test_name = parts[1]
                        if sort_test_name not in enrichment_test_names:
                            enrichment_test_names.append(sort_test_name)
        
        # Enrich if we have test_filters OR if we need to sort by a test metric
        needs_enrichment = test_filters or sort_test_name
        if needs_enrichment:
            # Fetch test results for these users for each test type in filters
            user_ids_for_metrics = [r["_id"] for r in results]
            
            # Build OR query for all test types we want to enrich with
            unique_test_names = list(set(enrichment_test_names))
            
            test_metrics_query = {
                "userId": {"$in": user_ids_for_metrics},
                "testName": {"$in": unique_test_names}
            }
            
            # Explicitly fetch all fields we need
            projection = {
                "userId": 1, "testName": 1, "timeTaken": 1, "speed": 1, 
                "distance": 1, "comparisonScore": 1, "performanceRating": 1, "date": 1
            }
            test_metrics_cursor = db.testresults.find(test_metrics_query, projection)
            test_metrics_data = await test_metrics_cursor.to_list(len(user_ids_for_metrics) * len(unique_test_names) * 2)
            
            # Create lookup: userId -> {testName -> test data}
            user_test_map = {}
            for tm in test_metrics_data:
                uid_str = str(tm.get("userId", ""))
                test_name = tm.get("testName", "")
                
                if uid_str not in user_test_map:
                    user_test_map[uid_str] = {}
                
                # Store data by test name
                user_test_map[uid_str][test_name] = {
                    "testName": test_name,
                    "timeTaken": tm.get("timeTaken"),
                    "speed": tm.get("speed"),
                    "distance": tm.get("distance"),
                    "comparisonScore": tm.get("comparisonScore"),
                    "performanceRating": tm.get("performanceRating"),
                    "date": tm.get("date")
                }
            
            # Enrich user results with test metrics for each test
            for user in serialized_results:
                user_id = user.get("id", "")
                if user_id in user_test_map:
                    user_tests = user_test_map[user_id]
                    user["testMetrics"] = user_tests
                    
                    # Also flatten the first test's metrics for backward compatibility
                    if unique_test_names and unique_test_names[0] in user_tests:
                        first_test = user_tests[unique_test_names[0]]
                        user["testName"] = first_test.get("testName")
                        user["timeTaken"] = first_test.get("timeTaken")
                        user["speed"] = first_test.get("speed")
                        user["distance"] = first_test.get("distance")
                        user["performanceRating"] = first_test.get("performanceRating")
            
            # Sort by test metrics if needed (these fields only exist after enrichment)
            test_metric_fields = ["timeTaken", "speed", "distance"]
            if query.sort:
                for s in query.sort:
                    sort_field = s.get("field")
                    sort_dir = s.get("dir", "asc")
                    reverse = sort_dir == "desc"
                    
                    # Check if it's a testFilter field (testFilter.TestName.metric)
                    if sort_field and sort_field.startswith("testFilter."):
                        parts = sort_field.split(".", 2)
                        if len(parts) == 3:
                            test_name = parts[1]
                            metric = parts[2]
                            # Sort using the nested testMetrics structure
                            serialized_results.sort(
                                key=lambda x, tn=test_name, m=metric: (x.get("testMetrics") or {}).get(tn, {}).get(m) or 0,
                                reverse=reverse
                            )
                            break
                    elif sort_field in test_metric_fields:
                        # Flat metric field (backward compatibility)
                        serialized_results.sort(
                            key=lambda x, sf=sort_field: x.get(sf) or 0,
                            reverse=reverse
                        )
                        break
        
        return {
            "total": total,
            "page": query.page,
            "limit": query.limit,
            "totalPages": (total + query.limit - 1) // query.limit,
            "results": serialized_results,
            "grouped": len(query.groupBy) > 0,
            "testFilters": [{"testName": tf["testName"], "metric": tf["metric"]} for tf in test_filters] if test_filters else []
        }
    except Exception as e:
        import traceback
        logger.error(f"Execute query error: {e}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(e))

# Verification Actions
@api_router.patch("/admin/candidates/{candidate_id}/verify")
async def verify_candidate(candidate_id: str, action: VerificationAction):
    """Update candidate verification status"""
    try:
        # Get current state
        candidate = await db.users.find_one({"_id": ObjectId(candidate_id)})
        if not candidate:
            raise HTTPException(status_code=404, detail="Candidate not found")
        
        before_state = candidate.get("verification", {})
        
        # Update verification status
        new_status = {
            "status": action.action,
            "adminId": action.adminId,
            "note": action.note,
            "updatedAt": datetime.now(timezone.utc).isoformat()
        }
        
        await db.users.update_one(
            {"_id": ObjectId(candidate_id)},
            {"$set": {"verification": new_status}}
        )
        
        # Log audit
        await log_audit(
            admin_id=action.adminId,
            action=f"verification_{action.action}",
            target_id=candidate_id,
            target_type="candidate",
            before=before_state,
            after=new_status,
            note=action.note
        )
        
        return {
            "success": True,
            "candidateId": candidate_id,
            "verification": new_status
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Verify candidate error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Audit Logs
@api_router.get("/admin/audit")
async def get_audit_logs(
    page: int = Query(1, ge=1),
    limit: int = Query(25, ge=1, le=100),
    targetId: Optional[str] = None,
    adminId: Optional[str] = None,
    action: Optional[str] = None,
    startDate: Optional[str] = None,
    endDate: Optional[str] = None
):
    """Get audit logs with filters"""
    try:
        filter_query = {}
        
        if targetId:
            filter_query["targetId"] = targetId
        if adminId:
            filter_query["adminId"] = adminId
        if action:
            filter_query["action"] = {"$regex": action, "$options": "i"}
        if startDate or endDate:
            filter_query["timestamp"] = {}
            if startDate:
                filter_query["timestamp"]["$gte"] = startDate
            if endDate:
                filter_query["timestamp"]["$lte"] = endDate
        
        total = await db.admin_audit.count_documents(filter_query)
        skip = (page - 1) * limit
        cursor = db.admin_audit.find(filter_query).sort("timestamp", -1).skip(skip).limit(limit)
        logs = await cursor.to_list(limit)
        
        return {
            "total": total,
            "page": page,
            "limit": limit,
            "totalPages": (total + limit - 1) // limit,
            "results": [serialize_doc(log) for log in logs]
        }
    except Exception as e:
        logger.error(f"Get audit logs error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@api_router.get("/admin/audit/{candidate_id}")
async def get_candidate_audit(candidate_id: str):
    """Get audit history for a specific candidate"""
    try:
        cursor = db.admin_audit.find({"targetId": candidate_id}).sort("timestamp", -1)
        logs = await cursor.to_list(100)
        return {"logs": [serialize_doc(log) for log in logs]}
    except Exception as e:
        logger.error(f"Get candidate audit error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Export
@api_router.get("/admin/export")
async def export_data(
    format: str = Query("json", enum=["json", "csv"]),
    type: str = Query("candidates", enum=["candidates", "test-results"]),
    state: Optional[str] = None,
    gender: Optional[str] = None,
    verificationStatus: Optional[str] = None,
    testType: Optional[str] = None,
    limit: int = Query(1000, ge=1, le=10000)
):
    """Export data as CSV or JSON"""
    try:
        filter_query = {}
        
        if type == "candidates":
            collection = db.users
            if state:
                filter_query["state"] = state
            if gender:
                filter_query["gender"] = gender
            if verificationStatus:
                filter_query["verification.status"] = verificationStatus
        else:
            collection = db.testresults
            if testType:
                filter_query["testType"] = testType
            if gender:
                filter_query["gender"] = gender
        
        cursor = collection.find(filter_query).limit(limit)
        data = await cursor.to_list(limit)
        serialized_data = [serialize_doc(d) for d in data]
        
        # Log export action
        await log_audit(
            admin_id="SAI_ADMIN_001",
            action="export",
            target_id="bulk",
            target_type=type,
            note=f"Exported {len(serialized_data)} {type} records as {format}"
        )
        
        if format == "csv":
            if not serialized_data:
                return Response(content="No data", media_type="text/csv")
            
            output = io.StringIO()
            
            # Flatten nested objects for CSV
            flat_data = []
            for item in serialized_data:
                flat_item = {}
                for key, value in item.items():
                    if isinstance(value, dict):
                        for k, v in value.items():
                            flat_item[f"{key}_{k}"] = v
                    elif isinstance(value, list):
                        flat_item[key] = str(value)[:200]  # Truncate arrays
                    else:
                        flat_item[key] = value
                flat_data.append(flat_item)
            
            # Get all possible headers
            headers = set()
            for item in flat_data:
                headers.update(item.keys())
            headers = sorted(list(headers))
            
            writer = csv.DictWriter(output, fieldnames=headers, extrasaction='ignore')
            writer.writeheader()
            writer.writerows(flat_data)
            
            csv_content = output.getvalue()
            
            return Response(
                content=csv_content,
                media_type="text/csv",
                headers={"Content-Disposition": f"attachment; filename=sai_export_{type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"}
            )
        else:
            return {
                "type": type,
                "count": len(serialized_data),
                "exportedAt": datetime.now(timezone.utc).isoformat(),
                "data": serialized_data
            }
    except Exception as e:
        logger.error(f"Export error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Filter Options (for dropdown population)
@api_router.get("/admin/filter-options")
async def get_filter_options():
    """Get available filter options from database"""
    try:
        # Get distinct values
        states = await db.users.distinct("state")
        cities = await db.users.distinct("city")
        genders = await db.users.distinct("gender")
        test_types = await db.testresults.distinct("testType")
        categories = await db.testresults.distinct("category")
        age_groups = await db.testresults.distinct("ageGroup")
        performance_ratings = await db.testresults.distinct("performanceRating")
        test_names = await db.testresults.distinct("testName")
        
        # Age range
        age_pipeline = [
            {"$group": {
                "_id": None,
                "minAge": {"$min": "$age"},
                "maxAge": {"$max": "$age"}
            }}
        ]
        age_range = await db.users.aggregate(age_pipeline).to_list(1)
        
        # Score range
        score_pipeline = [
            {"$group": {
                "_id": None,
                "minScore": {"$min": "$comparisonScore"},
                "maxScore": {"$max": "$comparisonScore"}
            }}
        ]
        score_range = await db.testresults.aggregate(score_pipeline).to_list(1)
        
        return {
            "states": sorted([s for s in states if s]),
            "cities": sorted([c for c in cities if c]),
            "genders": sorted([g for g in genders if g]),
            "testTypes": sorted([t for t in test_types if t]),
            "testNames": sorted([t for t in test_names if t]),
            "categories": sorted([c for c in categories if c]),
            "ageGroups": sorted([a for a in age_groups if a]),
            "performanceRatings": sorted([p for p in performance_ratings if p]),
            "ageRange": age_range[0] if age_range else {"minAge": 10, "maxAge": 40},
            "scoreRange": score_range[0] if score_range else {"minScore": 0, "maxScore": 100}
        }
    except Exception as e:
        logger.error(f"Filter options error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Quick filters presets
@api_router.get("/admin/quick-filters")
async def get_quick_filters():
    """Get preset quick filters"""
    today = datetime.now(timezone.utc).date()
    
    return {
        "presets": [
            {
                "id": "today",
                "name": "Today",
                "description": "Records from today",
                "filters": {"createdAt": {"$gte": today.isoformat()}}
            },
            {
                "id": "last_7_days",
                "name": "Last 7 Days",
                "description": "Records from last week",
                "filters": {"createdAt": {"$gte": (today - timedelta(days=7)).isoformat()}}
            },
            {
                "id": "last_30_days",
                "name": "Last 30 Days",
                "description": "Records from last month",
                "filters": {"createdAt": {"$gte": (today - timedelta(days=30)).isoformat()}}
            },
            {
                "id": "verified",
                "name": "Verified",
                "description": "All verified candidates",
                "filters": {"verification.status": "verified"}
            },
            {
                "id": "flagged",
                "name": "Flagged",
                "description": "All flagged candidates",
                "filters": {"verification.status": "flagged"}
            },
            {
                "id": "gold_performers",
                "name": "Gold Performers",
                "description": "Candidates with gold ratings",
                "filters": {}
            },
            {
                "id": "high_xp",
                "name": "High XP (>1000)",
                "description": "Top performers by XP",
                "filters": {"currentXP": {"$gte": 1000}}
            }
        ]
    }

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
