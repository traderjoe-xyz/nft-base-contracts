// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ISafePausableUpgradeable} from "./ISafePausableUpgradeable.sol";

interface INFTBaseUpgradeable is ISafePausableUpgradeable {
    error OperatorNotAllowed(address operator);
    error NFTBase__InvalidPercent();
    error NFTBase__InvalidJoeFeeCollector();
    error NFTBase__WithdrawAVAXNotAvailable();
    error NFTBase__TransferFailed();
    error NFTBase__NotEnoughAVAX(uint256 amountNeeded);
    error NFTBase__InvalidRoyaltyInfo();

    event OperatorFilterRegistryUpdated(address indexed operatorFilterRegistry);
    event JoeFeeInitialized(uint256 feePercent, address feeCollector);
    event WithdrawAVAXStartTimeSet(uint256 withdrawAVAXStartTime);
    event AvaxWithdraw(address indexed sender, uint256 amount, uint256 fee);
    event DefaultRoyaltySet(address indexed receiver, uint256 feePercent);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
