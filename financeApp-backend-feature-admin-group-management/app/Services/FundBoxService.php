<?php

namespace App\Services;

use App\Models\FundBox;
use App\Models\Transfer;
use App\Models\Incoming;
use App\Models\User;
use App\Repositories\FundBoxRepository;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class FundBoxService
{
    /**
     * Create a new FundBoxService instance.
     *
     * @param FundBoxRepository $fundBoxRepository
     */
    public function __construct(
        protected FundBoxRepository $fundBoxRepository
    ) {}

    /**
     * Get the fund box record for a specific user.
     * For admins, returns their fund box.
     * For regular users, returns their own fund box.
     *
     * @param User $user
     * @return FundBox
     */
    public function getFundBoxForUser(User $user): FundBox
    {
        return $this->fundBoxRepository->getFundBoxForUser($user);
    }

    /**
     * Get the fund box record (legacy method).
     *
     * @return FundBox
     * @deprecated Use getFundBoxForUser() instead
     */
    public function getFundBox(): FundBox
    {
        return $this->fundBoxRepository->getFundBox();
    }

    /**
     * Update the fund box balance with validation for a specific user.
     *
     * @param User $user
     * @param float $newBalance
     * @return FundBox
     * @throws InvalidArgumentException
     */
    public function updateBalanceForUser(User $user, float $newBalance): FundBox
    {
        if ($newBalance < 0) {
            throw new InvalidArgumentException('Fund box balance cannot be negative.');
        }

        return $this->fundBoxRepository->updateBalanceForUser($user, $newBalance);
    }

    /**
     * Update the fund box balance with validation (legacy method).
     *
     * @param float $newBalance
     * @return FundBox
     * @throws InvalidArgumentException
     * @deprecated Use updateBalanceForUser() instead
     */
    public function updateBalance(float $newBalance): FundBox
    {
        if ($newBalance < 0) {
            throw new InvalidArgumentException('Fund box balance cannot be negative.');
        }

        return $this->fundBoxRepository->updateBalance($newBalance);
    }

    /**
     * Adjust the fund box balance by a specific amount for a user.
     *
     * @param User $user
     * @param float $amount
     * @return FundBox
     * @throws InvalidArgumentException
     */
    public function adjustBalanceForUser(User $user, float $amount): FundBox
    {
        $fundBox = $this->getFundBoxForUser($user);
        $newBalance = $fundBox->balance_usd + $amount;

        if ($newBalance < 0) {
            throw new InvalidArgumentException('Adjustment would result in negative balance.');
        }

        return $this->fundBoxRepository->updateBalanceForUser($user, $newBalance);
    }

    /**
     * Adjust the fund box balance by a specific amount (legacy method).
     *
     * @param float $amount
     * @return FundBox
     * @throws InvalidArgumentException
     * @deprecated Use adjustBalanceForUser() instead
     */
    public function adjustBalance(float $amount): FundBox
    {
        $fundBox = $this->getFundBox();
        $newBalance = $fundBox->balance_usd + $amount;

        if ($newBalance < 0) {
            throw new InvalidArgumentException('Adjustment would result in negative balance.');
        }

        return $this->fundBoxRepository->updateBalance($newBalance);
    }

    /**
     * Recalculate the fund box balance from all transactions for a specific user.
     * Formula: Total Incoming - Total Transfers
     * For admins: calculates based on all group members' transactions
     * For regular users: calculates based on their own transactions
     *
     * @param User $user
     * @return FundBox
     */
    public function recalculateBalanceForUser(User $user): FundBox
    {
        return DB::transaction(function () use ($user) {
            if ($user->isAdmin() && $user->managedGroup) {
                // Admin: calculate from all group members' transactions
                $groupMemberIds = $user->managedGroup->members()->pluck('id')->toArray();
                $groupMemberIds[] = $user->id; // Include admin's own transactions

                $totalIncoming = Incoming::whereNull('deleted_at')
                    ->whereIn('user_id', $groupMemberIds)
                    ->sum('amount_usd');

                $totalTransfers = Transfer::whereNull('deleted_at')
                    ->whereIn('user_id', $groupMemberIds)
                    ->sum('amount_usd');
            } else {
                // Regular user: calculate from own transactions only
                $totalIncoming = Incoming::whereNull('deleted_at')
                    ->where('user_id', $user->id)
                    ->sum('amount_usd');

                $totalTransfers = Transfer::whereNull('deleted_at')
                    ->where('user_id', $user->id)
                    ->sum('amount_usd');
            }

            // Calculate balance
            $calculatedBalance = $totalIncoming - $totalTransfers;

            // Update fund box
            $fundBox = $this->fundBoxRepository->getFundBoxForUser($user);
            $fundBox->update([
                'balance_usd' => $calculatedBalance,
                'last_calculated_at' => now(),
            ]);

            return $fundBox->fresh();
        });
    }

    /**
     * Recalculate the fund box balance from all transactions (legacy method).
     * Formula: Total Incoming - Total Transfers
     *
     * @return FundBox
     * @deprecated Use recalculateBalanceForUser() instead
     */
    public function recalculateBalance(): FundBox
    {
        return DB::transaction(function () {
            // Calculate total incoming funds
            $totalIncoming = Incoming::whereNull('deleted_at')
                ->sum('amount_usd');

            // Calculate total transfers
            $totalTransfers = Transfer::whereNull('deleted_at')
                ->sum('amount_usd');

            // Calculate balance
            $calculatedBalance = $totalIncoming - $totalTransfers;

            // Update fund box
            $fundBox = $this->fundBoxRepository->getFundBox();
            $fundBox->update([
                'balance_usd' => $calculatedBalance,
                'last_calculated_at' => now(),
            ]);

            return $fundBox->fresh();
        });
    }
}
