// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.19;

/**
 * @title Sablier Types
 * @author Sablier
 */
library Types {
    struct Stream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        uint256 cancelFee;
        address recipient;
        address sender;
        address tokenAddress;
        bool isEntity;
    }
}
