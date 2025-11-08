<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RequireRecentAuthentication
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated.',
                'error_code' => 'UNAUTHENTICATED',
            ], 401);
        }
        
        // Check if the user has authenticated recently (within 15 minutes)
        $lastAuthTime = $user->tokens()
            ->where('id', $request->user()->currentAccessToken()->id)
            ->first()
            ->created_at;
        
        $minutesSinceAuth = now()->diffInMinutes($lastAuthTime);
        
        if ($minutesSinceAuth > 15) {
            return response()->json([
                'success' => false,
                'message' => 'Recent authentication required. Please re-authenticate to perform this action.',
                'error_code' => 'RECENT_AUTH_REQUIRED',
                'minutes_since_auth' => $minutesSinceAuth,
            ], 403);
        }
        
        return $next($request);
    }
}
