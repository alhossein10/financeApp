# Backend Guide: User Fundbox Access for User Flavor

## Problem
The `/fund-box` endpoint currently requires admin permissions (returns 403). For user flavor, users need to:
1. **Read** their own fundbox balance (calculated as: USD transfers from admin + exchanges to SYP/TRY)
2. Users should **NOT** be able to update/manual modify fundbox (only admins can)

## Solution

**Recommended Approach**: Modify the existing `/fund-box` endpoint to support both admin and user access, with different logic based on user role. This is cleaner than creating a separate endpoint.

**Alternative**: Create a new endpoint `/api/users/fund-box` if you prefer separation.

## Backend Changes Required

### 1. Create User Fundbox Controller

**File**: `app/Http/Controllers/UserFundBoxController.php`

```php
<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\FundBox;
use App\Models\Transfer;
use App\Models\Exchange;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class UserFundBoxController extends Controller
{
    /**
     * Get user's fundbox balance
     * 
     * Calculates user balance as:
     * - USD: Sum of incoming transfers from admin + exchanges to SYP/TRY
     * - SYP: Sum of exchanges to SYP
     * - TRY: Sum of exchanges to TRY
     * 
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUserFundBox()
    {
        $user = Auth::user();
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        // Get user's admin group ID
        $adminGroupId = $user->admin_group_id;
        
        if (!$adminGroupId) {
            return response()->json([
                'success' => false,
                'message' => 'User is not part of any admin group',
            ], 403);
        }

        try {
            // Calculate USD balance: Sum of incoming transfers from admin to this user
            $usdBalance = Transfer::where('user_id', $user->id)
                ->where('admin_group_id', $adminGroupId)
                ->sum('amount_usd');
            
            // Subtract USD used in exchanges
            $usdUsedInExchanges = Exchange::where('user_id', $user->id)
                ->where('admin_group_id', $adminGroupId)
                ->sum('amount_usd');
            
            $usdBalance = max(0, $usdBalance - $usdUsedInExchanges);
            
            // Calculate SYP balance: Sum of exchanges to SYP
            $sypBalance = Exchange::where('user_id', $user->id)
                ->where('admin_group_id', $adminGroupId)
                ->where('target_currency', 'SYP')
                ->sum(DB::raw('amount_usd * exchange_rate'));
            
            // Calculate TRY balance: Sum of exchanges to TRY
            $tryBalance = Exchange::where('user_id', $user->id)
                ->where('admin_group_id', $adminGroupId)
                ->where('target_currency', 'TRY')
                ->sum(DB::raw('amount_usd * exchange_rate'));
            
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $user->id, // Use user ID as fundbox ID
                    'user_id' => $user->id,
                    'balance_usd' => round($usdBalance, 2),
                    'balance_syp' => round($sypBalance, 2),
                    'balance_try' => round($tryBalance, 2),
                    'updated_at' => now()->toISOString(),
                ],
            ], 200);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error calculating fundbox balance: ' . $e->getMessage(),
            ], 500);
        }
    }
}
```

### 2. Add Route

**File**: `routes/api.php`

Add this route:

```php
// User fundbox endpoint (for user flavor)
Route::middleware(['auth:sanctum'])->group(function () {
    // User can read their own fundbox balance
    Route::get('/users/fund-box', [UserFundBoxController::class, 'getUserFundBox']);
    
    // Keep existing admin fundbox routes
    Route::middleware(['admin'])->group(function () {
        Route::get('/fund-box', [FundBoxController::class, 'index']);
        Route::put('/fund-box', [FundBoxController::class, 'update']);
    });
});
```

### 3. Update Frontend API Data Source

**File**: `lib/features/fund_box/data/datasources/fund_box_api_datasource.dart`

Update the `getFundBox` method to use the user endpoint when in user flavor:

```dart
@override
Future<FundBoxDto> getFundBox({String? currency}) async {
  try {
    // For user flavor, use user-specific endpoint
    // Check if user is admin (can be determined from FlavorConfig or user role)
    final authState = // Get auth state somehow or pass as parameter
    final isAdmin = authState?.user?.isAdmin ?? false;
    
    String url = isAdmin ? '/fund-box' : '/users/fund-box';
    if (currency != null && currency.isNotEmpty) {
      url += '?currency=$currency';
    }
    
    final response = await apiClient.get(url);

    if (response.statusCode == 200) {
      final data = response.data['data'] as Map<String, dynamic>;
      return FundBoxDto.fromJson(data);
    } else if (response.statusCode == 403) {
      throw ApiException(
        statusCode: 403,
        message: 'Access denied. Admin privileges required.',
      );
    } else {
      throw ApiException(
        statusCode: response.statusCode ?? 500,
        message: response.data['message'] ?? 'Failed to get fund box',
      );
    }
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      statusCode: 500,
      message: 'Unexpected error: ${e.toString()}',
    );
  }
}
```

**OR** better approach: Check FlavorConfig in the repository layer:

**File**: `lib/features/fund_box/data/repositories/fund_box_repository_impl.dart`

Actually, a simpler approach is to modify the API client to use different endpoints based on the request. But the cleanest is to pass a flag or check in the data source.

### 4. Alternative: Modify Existing Endpoint to Support Both

If you prefer to modify the existing endpoint instead of creating a new one:

**File**: `app/Http/Controllers/FundBoxController.php`

```php
public function index(Request $request)
{
    $user = Auth::user();
    
    // If user is admin, return admin group fundbox
    if ($user->isAdmin() || $user->role === 1) {
        // Existing admin logic
        $fundBox = FundBox::where('admin_group_id', $user->admin_group_id ?? $user->managed_group_id)
            ->firstOrFail();
            
        return response()->json([
            'success' => true,
            'data' => $fundBox,
        ]);
    }
    
    // If user is regular user, calculate their balance
    $adminGroupId = $user->admin_group_id;
    
    if (!$adminGroupId) {
        return response()->json([
            'success' => false,
            'message' => 'User is not part of any admin group',
        ], 403);
    }
    
    // Calculate user balance (same logic as UserFundBoxController above)
    $usdBalance = Transfer::where('user_id', $user->id)
        ->where('admin_group_id', $adminGroupId)
        ->sum('amount_usd');
    
    $usdUsedInExchanges = Exchange::where('user_id', $user->id)
        ->where('admin_group_id', $adminGroupId)
        ->sum('amount_usd');
    
    $usdBalance = max(0, $usdBalance - $usdUsedInExchanges);
    
    $sypBalance = Exchange::where('user_id', $user->id)
        ->where('admin_group_id', $adminGroupId)
        ->where('target_currency', 'SYP')
        ->sum(DB::raw('amount_usd * exchange_rate'));
    
    $tryBalance = Exchange::where('user_id', $user->id)
        ->where('admin_group_id', $adminGroupId)
        ->where('target_currency', 'TRY')
        ->sum(DB::raw('amount_usd * exchange_rate'));
    
    return response()->json([
        'success' => true,
        'data' => [
            'id' => $user->id,
            'user_id' => $user->id,
            'balance_usd' => round($usdBalance, 2),
            'balance_syp' => round($sypBalance, 2),
            'balance_try' => round($tryBalance, 2),
            'updated_at' => now()->toISOString(),
        ],
    ]);
}
```

And update the route to remove the admin middleware:

```php
Route::middleware(['auth:sanctum'])->group(function () {
    // Allow both admins and users to read fundbox
    Route::get('/fund-box', [FundBoxController::class, 'index']);
    
    // Only admins can update fundbox
    Route::middleware(['admin'])->group(function () {
        Route::put('/fund-box', [FundBoxController::class, 'update']);
    });
});
```

## Database Schema Requirements

Make sure your database has the following:

1. **transfers table**:
   - `user_id` - The user receiving the transfer
   - `admin_group_id` - The admin group
   - `amount_usd` - Transfer amount in USD

2. **exchanges table**:
   - `user_id` - The user making the exchange
   - `admin_group_id` - The admin group
   - `target_currency` - 'SYP' or 'TRY'
   - `amount_usd` - Amount in USD being exchanged
   - `exchange_rate` - Exchange rate

## Testing

1. **Test as Admin**: Should get admin group fundbox
2. **Test as User**: Should get calculated user balance
3. **Test user not in group**: Should return 403 error
4. **Test unauthenticated**: Should return 401 error

## Notes

- User balance is **calculated on-the-fly** (not stored)
- Users can only **read** their balance (not update)
- Balance calculation:
  - USD = (Incoming transfers from admin) - (USD used in exchanges)
  - SYP = Sum of exchanges to SYP
  - TRY = Sum of exchanges to TRY

