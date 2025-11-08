<?php

namespace App\Repositories;

use App\Models\FundBox;
use App\Models\User;

class FundBoxRepository extends BaseRepository
{
    /**
     * Create a new FundBoxRepository instance.
     *
     * @param FundBox $fundBox
     */
    public function __construct(FundBox $fundBox)
    {
        parent::__construct($fundBox);
    }

    /**
     * Get the fund box record for a specific user.
     * Creates it if it doesn't exist.
     *
     * @param User $user
     * @return FundBox
     */
    public function getFundBoxForUser(User $user): FundBox
    {
        $fundBox = $this->model->where('user_id', $user->id)->first();
        
        if (!$fundBox) {
            $fundBox = $this->model->create([
                'user_id' => $user->id,
                'balance_usd' => 0.00,
                'last_calculated_at' => now(),
            ]);
        }
        
        return $fundBox;
    }

    /**
     * Get the single fund box record (legacy method for backward compatibility).
     * Creates it if it doesn't exist.
     *
     * @return FundBox
     * @deprecated Use getFundBoxForUser() instead
     */
    public function getFundBox(): FundBox
    {
        $fundBox = $this->model->find(1);
        
        if (!$fundBox) {
            $fundBox = $this->model->create([
                'id' => 1,
                'balance_usd' => 0.00,
                'last_calculated_at' => now(),
            ]);
        }
        
        return $fundBox;
    }

    /**
     * Update the fund box balance for a specific user.
     *
     * @param User $user
     * @param float $balance
     * @return FundBox
     */
    public function updateBalanceForUser(User $user, float $balance): FundBox
    {
        $fundBox = $this->getFundBoxForUser($user);
        $fundBox->update([
            'balance_usd' => $balance,
            'last_calculated_at' => now(),
        ]);
        
        return $fundBox->fresh();
    }

    /**
     * Update the fund box balance.
     *
     * @param float $balance
     * @return FundBox
     * @deprecated Use updateBalanceForUser() instead
     */
    public function updateBalance(float $balance): FundBox
    {
        $fundBox = $this->getFundBox();
        $fundBox->update([
            'balance_usd' => $balance,
            'last_calculated_at' => now(),
        ]);
        
        return $fundBox->fresh();
    }

    /**
     * Adjust the fund box balance by a specific amount for a user.
     *
     * @param User $user
     * @param float $amount
     * @return FundBox
     */
    public function adjustBalanceForUser(User $user, float $amount): FundBox
    {
        $fundBox = $this->getFundBoxForUser($user);
        $newBalance = $fundBox->balance_usd + $amount;
        
        return $this->updateBalanceForUser($user, $newBalance);
    }

    /**
     * Adjust the fund box balance by a specific amount.
     *
     * @param float $amount
     * @return FundBox
     * @deprecated Use adjustBalanceForUser() instead
     */
    public function adjustBalance(float $amount): FundBox
    {
        $fundBox = $this->getFundBox();
        $newBalance = $fundBox->balance_usd + $amount;
        
        return $this->updateBalance($newBalance);
    }
}
