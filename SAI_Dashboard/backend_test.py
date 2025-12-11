#!/usr/bin/env python3

import requests
import sys
import json
from datetime import datetime

class SAIBackendTester:
    def __init__(self, base_url="https://sai-scout-portal.preview.emergentagent.com"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"
        self.tests_run = 0
        self.tests_passed = 0
        self.failed_tests = []

    def run_test(self, name, method, endpoint, expected_status, data=None, params=None):
        """Run a single API test"""
        url = f"{self.api_url}/{endpoint}"
        headers = {'Content-Type': 'application/json'}

        self.tests_run += 1
        print(f"\n🔍 Testing {name}...")
        print(f"   URL: {url}")
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=headers, params=params, timeout=30)
            elif method == 'POST':
                response = requests.post(url, json=data, headers=headers, timeout=30)
            elif method == 'PATCH':
                response = requests.patch(url, json=data, headers=headers, timeout=30)

            print(f"   Status: {response.status_code}")
            
            success = response.status_code == expected_status
            if success:
                self.tests_passed += 1
                print(f"✅ PASSED - {name}")
                try:
                    response_data = response.json()
                    if isinstance(response_data, dict):
                        if 'total' in response_data:
                            print(f"   Data: Found {response_data.get('total', 0)} records")
                        elif 'totalCandidates' in response_data:
                            print(f"   Data: {response_data.get('totalCandidates', 0)} candidates, {response_data.get('totalTests', 0)} tests")
                        elif 'results' in response_data:
                            print(f"   Data: {len(response_data.get('results', []))} results")
                except:
                    print(f"   Response: {response.text[:100]}...")
            else:
                print(f"❌ FAILED - Expected {expected_status}, got {response.status_code}")
                print(f"   Error: {response.text[:200]}")
                self.failed_tests.append({
                    'name': name,
                    'expected': expected_status,
                    'actual': response.status_code,
                    'error': response.text[:200]
                })

            return success, response.json() if success and response.text else {}

        except Exception as e:
            print(f"❌ FAILED - Exception: {str(e)}")
            self.failed_tests.append({
                'name': name,
                'expected': expected_status,
                'actual': 'Exception',
                'error': str(e)
            })
            return False, {}

    def test_root_endpoint(self):
        """Test API root endpoint"""
        return self.run_test("API Root", "GET", "", 200)

    def test_dashboard_stats(self):
        """Test dashboard statistics"""
        return self.run_test("Dashboard Stats", "GET", "admin/dashboard", 200)

    def test_candidates_list(self):
        """Test candidates list with pagination"""
        return self.run_test("Candidates List", "GET", "admin/candidates", 200, params={'page': 1, 'limit': 10})

    def test_candidates_with_filters(self):
        """Test candidates with filters"""
        return self.run_test("Candidates with Filters", "GET", "admin/candidates", 200, 
                           params={'page': 1, 'limit': 5, 'gender': 'Male'})

    def test_filter_options(self):
        """Test filter options endpoint"""
        return self.run_test("Filter Options", "GET", "admin/filter-options", 200)

    def test_test_results(self):
        """Test test results endpoint"""
        return self.run_test("Test Results", "GET", "admin/test-results", 200, params={'page': 1, 'limit': 10})

    def test_audit_logs(self):
        """Test audit logs endpoint"""
        return self.run_test("Audit Logs", "GET", "admin/audit", 200, params={'page': 1, 'limit': 10})

    def test_export_json(self):
        """Test export functionality (JSON)"""
        return self.run_test("Export JSON", "GET", "admin/export", 200, 
                           params={'format': 'json', 'type': 'candidates', 'limit': 5})

    def test_query_builder(self):
        """Test query builder with simple query"""
        query_data = {
            "filters": {"gender": "Male"},
            "sort": [{"field": "createdAt", "dir": "desc"}],
            "groupBy": [],
            "aggregate": [],
            "page": 1,
            "limit": 5
        }
        return self.run_test("Query Builder", "POST", "admin/query", 200, data=query_data)

    def test_candidate_profile(self):
        """Test individual candidate profile - need to get a valid ID first"""
        # First get candidates list to get a valid ID
        success, candidates_data = self.test_candidates_list()
        if success and candidates_data.get('results'):
            candidate_id = candidates_data['results'][0].get('id')
            if candidate_id:
                return self.run_test("Candidate Profile", "GET", f"admin/candidates/{candidate_id}", 200)
        
        print("⚠️  Skipping Candidate Profile test - no valid candidate ID found")
        return False, {}

    def test_verification_action(self):
        """Test verification action - need a valid candidate ID"""
        # First get candidates list to get a valid ID
        success, candidates_data = self.run_test("Get Candidates for Verification", "GET", "admin/candidates", 200, params={'limit': 1})
        if success and candidates_data.get('results'):
            candidate_id = candidates_data['results'][0].get('id')
            if candidate_id:
                verification_data = {
                    "action": "verified",
                    "note": "Test verification from backend test",
                    "adminId": "SAI_ADMIN_001"
                }
                return self.run_test("Verification Action", "PATCH", f"admin/candidates/{candidate_id}/verify", 200, data=verification_data)
        
        print("⚠️  Skipping Verification test - no valid candidate ID found")
        return False, {}

def main():
    print("🚀 Starting SAI Backend API Tests")
    print("=" * 50)
    
    tester = SAIBackendTester()
    
    # Run all tests
    test_methods = [
        tester.test_root_endpoint,
        tester.test_dashboard_stats,
        tester.test_candidates_list,
        tester.test_candidates_with_filters,
        tester.test_filter_options,
        tester.test_test_results,
        tester.test_audit_logs,
        tester.test_export_json,
        tester.test_query_builder,
        tester.test_candidate_profile,
        tester.test_verification_action,
    ]
    
    for test_method in test_methods:
        try:
            test_method()
        except Exception as e:
            print(f"❌ Test method {test_method.__name__} failed with exception: {e}")
            tester.failed_tests.append({
                'name': test_method.__name__,
                'expected': 'Success',
                'actual': 'Exception',
                'error': str(e)
            })
    
    # Print results
    print("\n" + "=" * 50)
    print("📊 TEST RESULTS")
    print("=" * 50)
    print(f"Tests Run: {tester.tests_run}")
    print(f"Tests Passed: {tester.tests_passed}")
    print(f"Tests Failed: {len(tester.failed_tests)}")
    print(f"Success Rate: {(tester.tests_passed / tester.tests_run * 100):.1f}%" if tester.tests_run > 0 else "0%")
    
    if tester.failed_tests:
        print("\n❌ FAILED TESTS:")
        for i, test in enumerate(tester.failed_tests, 1):
            print(f"{i}. {test['name']}")
            print(f"   Expected: {test['expected']}")
            print(f"   Actual: {test['actual']}")
            print(f"   Error: {test['error']}")
    
    return 0 if len(tester.failed_tests) == 0 else 1

if __name__ == "__main__":
    sys.exit(main())