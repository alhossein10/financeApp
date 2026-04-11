@echo off
echo ========================================
echo Running Comprehensive Test Suite
echo ========================================
echo.

echo [1/6] Running Unit Tests...
echo ----------------------------------------
call flutter test test/core/ --coverage
if %errorlevel% neq 0 (
    echo ERROR: Unit tests failed!
    pause
    exit /b 1
)
echo Unit tests passed!
echo.

echo [2/6] Running Feature Tests...
echo ----------------------------------------
call flutter test test/features/ --coverage
if %errorlevel% neq 0 (
    echo ERROR: Feature tests failed!
    pause
    exit /b 1
)
echo Feature tests passed!
echo.

echo [3/6] Running Widget Tests...
echo ----------------------------------------
call flutter test test/widgets/ --coverage
if %errorlevel% neq 0 (
    echo ERROR: Widget tests failed!
    pause
    exit /b 1
)
echo Widget tests passed!
echo.

echo [4/6] Running Integration Tests...
echo ----------------------------------------
call flutter test test/integration/ --coverage
if %errorlevel% neq 0 (
    echo ERROR: Integration tests failed!
    pause
    exit /b 1
)
echo Integration tests passed!
echo.

echo [5/6] Running Flavor-Specific Tests...
echo ----------------------------------------
call flutter test test/flavors/ --coverage
if %errorlevel% neq 0 (
    echo ERROR: Flavor tests failed!
    pause
    exit /b 1
)
echo Flavor tests passed!
echo.

echo [6/6] Running E2E Tests...
echo ----------------------------------------
call flutter test test/e2e/ --coverage
if %errorlevel% neq 0 (
    echo ERROR: E2E tests failed!
    pause
    exit /b 1
)
echo E2E tests passed!
echo.

echo ========================================
echo Generating Coverage Report...
echo ========================================
call flutter test --coverage
call genhtml coverage/lcov.info -o coverage/html
echo Coverage report generated at coverage/html/index.html
echo.

echo ========================================
echo All Tests Passed Successfully!
echo ========================================
echo.
echo Test Summary:
echo - Unit Tests: PASSED
echo - Feature Tests: PASSED
echo - Widget Tests: PASSED
echo - Integration Tests: PASSED
echo - Flavor Tests: PASSED
echo - E2E Tests: PASSED
echo.
echo Next Steps:
echo 1. Review coverage report
echo 2. Run manual tests from test_execution_plan.md
echo 3. Test all three flavor builds
echo 4. Document any bugs in bug_tracker.md
echo.
pause
