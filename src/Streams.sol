// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IStreams.sol";
import "./Types.sol";

/**
 * @title Streams
 * @author Kernel
 * @notice Money streaming, slightly adapted for our specific use case from the awesome work done by Sablier
 *
 * We have made a few notable changes to this contract, which are all documented here
 * 1. We are using Foundry rather than Truffle as our dev framework - it's also Paul Razvan Berg template. Thanks Paul!
 * 2. Updated solidity compiler version from 0.5.17 to 0.8.19
 * 3. Updated OpenZeppelin libraries from 2.3.0 to 4.8.1
 * 4. Removed SafeERC20 and CarefulMath. Due to the above compiler + library updates, they are no longer required
 * 5. Updated the import path for ReentrancyGuard.sol
 * 6. Updated require statement descriptions to avoid linting errors
 * 7. Updated safeTransferFrom to transferFrom and safeTransfer to transfer - the library updates again cover this well
 * 8. Removed constructor visibility - no longer required
 * 9. Updated the comments for return statements to make solhint happy 
 * 10. Added a "cancelFee" for stopping the stream, to give contributors greater ease of mind.
 */
contract Streams is IStreams, ReentrancyGuard {

    /*** Storage Properties ***/

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;

    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Types.Stream) private streams;

    /*** Modifiers ***/

    /**
     * @dev Throws if the caller is not the sender of the recipient of the stream.
     */
    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender || msg.sender == streams[streamId].recipient,
            "not sender or recipient"
        );
        _;
    }

    /**
     * @dev Throws if the provided id does not point to a valid stream.
     */
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }

    /*** Contract Logic Starts Here */

    constructor() {
        nextStreamId = 1;
    }

    /*** View Functions ***/

    /**
     * @notice Returns the stream with all its properties.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream to query.
     * @return sender recipient deposit tokenAddress startTime stopTime remainingBalance ratePerSecond
     */
    function getStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            uint256 cancelFee
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
        cancelFee = streams[streamId].cancelFee;
    }

    /**
     * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
     *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
     *  `startTime`, it returns 0.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for which to query the delta.
     * @return delta the time change in seconds.
     */
    function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
        Types.Stream memory stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    struct BalanceOfLocalVars {
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }

    /**
     * @notice Returns the available funds for the given stream id and address.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for which to query the balance.
     * @param who The address for which to query the balance.
     * @return balance total funds allocated to `who` as uint256.
     */
    function balanceOf(uint256 streamId, address who) public view streamExists(streamId) returns (uint256 balance) {
        Types.Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        vars.recipientBalance = delta * stream.ratePerSecond;

        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        if (stream.deposit > stream.remainingBalance) {
            vars.withdrawalAmount = stream.deposit - stream.remainingBalance;
            vars.recipientBalance = vars.recipientBalance - vars.withdrawalAmount;
        }

        if (who == stream.recipient) return vars.recipientBalance;
        if (who == stream.sender) {
            vars.senderBalance = stream.remainingBalance - vars.recipientBalance;
            return vars.senderBalance;
        }
        return 0;
    }

    /*** Public Effects & Interactions Functions ***/

    struct CreateStreamLocalVars {
        uint256 duration;
        uint256 ratePerSecond;
    }

    /**
     * @notice Creates a new stream funded by `msg.sender` and paid towards `recipient`.
     * @dev Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the deposit is 0.
     *  Throws if the start time is before `block.timestamp`.
     *  Throws if the stop time is before the start time.
     *  Throws if the deposit is smaller than the duration.
     *  Throws if the deposit is not a multiple of the duration.
     *  Throws if the fee to cancel is greater than the stream itself
     *  Throws if the contract is not allowed to transfer enough tokens.
     *  Throws if there is a token transfer failure.
     * @param recipient The address towards which the money is streamed.
     * @param deposit The amount of money to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @param cancelFee the fee to cancel the stream. Can be 0. Assumed to be in the same asset as the stream itself.
     * @return uint256 id of the newly created stream.
     */
    function createStream(
        address recipient, 
        uint256 deposit, 
        address tokenAddress, 
        uint256 startTime, 
        uint256 stopTime, 
        uint256 cancelFee
    )
        public
        returns (uint256)
    {
        require(recipient != address(0x00), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(deposit > 0, "deposit is zero");
        require(startTime >= block.timestamp, "stream has not started");
        require(stopTime > startTime, "stop time before the start time");

        CreateStreamLocalVars memory vars;
        vars.duration = stopTime - startTime;

        /* Without this, the rate per second would be zero. */
        require(deposit >= vars.duration, "smaller than time delta");

        /* This condition avoids dealing with remainders */
        require(deposit % vars.duration == 0, "not multiple of time delta");

        vars.ratePerSecond = deposit / vars.duration;

        require(cancelFee < deposit, "fee must be less than deposit");

        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;
        streams[streamId] = Types.Stream({
            remainingBalance: deposit,
            deposit: deposit,
            isEntity: true,
            ratePerSecond: vars.ratePerSecond,
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            stopTime: stopTime,
            cancelFee: cancelFee,
            tokenAddress: tokenAddress
        });

        /* Increment the next stream id. */
        nextStreamId++;

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), deposit);
        emit CreateStream(streamId, msg.sender, recipient, deposit, tokenAddress, startTime, stopTime, cancelFee);
        return streamId;
    }

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to withdraw tokens from.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        require(amount > 0, "amount is zero");
        Types.Stream memory stream = streams[streamId];

        uint256 balance = balanceOf(streamId, stream.recipient);
        require(balance >= amount, "exceeds available balance");

        streams[streamId].remainingBalance = stream.remainingBalance - amount;

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        IERC20(stream.tokenAddress).transfer(stream.recipient, amount);
        emit WithdrawFromStream(streamId, stream.recipient, amount);
        return true;
    }

    /**
     * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to cancel.
     * @return bool true=success, otherwise false.
     */
    function cancelStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        Types.Stream memory stream = streams[streamId];
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);
        uint256 cancelFee = stream.cancelFee;

        delete streams[streamId];

        IERC20 token = IERC20(stream.tokenAddress);
        if (recipientBalance > 0) token.transfer(stream.recipient, recipientBalance + cancelFee);
        if (senderBalance > 0) token.transfer(stream.sender, senderBalance - cancelFee);

        emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance, cancelFee);
        return true;
    }
}
