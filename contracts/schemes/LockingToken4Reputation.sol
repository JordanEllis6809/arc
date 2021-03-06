pragma solidity ^0.4.25;

import "./Locking4Reputation.sol";
import "./PriceOracleInterface.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";


/**
 * @title A scheme for locking ERC20 Tokens for reputation
 */

contract LockingToken4Reputation is Locking4Reputation, Ownable {

    PriceOracleInterface public priceOracleContract;
    //      lockingId => token
    mapping(bytes32   => StandardToken) public lockedTokens;

    event LockToken(bytes32 indexed _lockingId, address indexed _token, uint _numerator, uint _denominator);

    /**
     * @dev initialize
     * @param _avatar the avatar to mint reputation from
     * @param _reputationReward the total reputation this contract will reward
     *        for the token locking
     * @param _lockingStartTime locking starting period time.
     * @param _lockingEndTime the locking end time.
     *        locking is disable after this time.
     * @param _redeemEnableTime redeem enable time .
     *        redeem reputation can be done after this time.
     * @param _maxLockingPeriod maximum locking period allowed.
     * @param _priceOracleContract the price oracle contract which the locked token will be
     *        validated against
     */
    function initialize(
        Avatar _avatar,
        uint _reputationReward,
        uint _lockingStartTime,
        uint _lockingEndTime,
        uint _redeemEnableTime,
        uint _maxLockingPeriod,
        PriceOracleInterface _priceOracleContract)
    external
    onlyOwner
    {
        priceOracleContract = _priceOracleContract;
        super._initialize(
        _avatar,
        _reputationReward,
        _lockingStartTime,
        _lockingEndTime,
        _redeemEnableTime,
        _maxLockingPeriod);
    }

    /**
     * @dev release locked tokens
     * @param _beneficiary the release _beneficiary
     * @param _lockingId the locking id
     * @return bool
     */
    function release(address _beneficiary,bytes32 _lockingId) public returns(bool) {
        uint amount = super._release(_beneficiary, _lockingId);
        require(lockedTokens[_lockingId].transfer(_beneficiary, amount), "transfer should success");

        return true;
    }

    /**
     * @dev lock function
     * @param _amount the amount to lock
     * @param _period the locking period
     * @param _token the token to lock - this should be whitelisted at the priceOracleContract
     * @return lockingId
     */
    function lock(uint _amount, uint _period,StandardToken _token) public returns(bytes32 lockingId) {

        uint numerator;
        uint denominator;

        (numerator,denominator) = priceOracleContract.getPrice(address(_token));

        require(numerator > 0,"numerator should be > 0");
        require(denominator > 0,"denominator should be > 0");

        require(_token.transferFrom(msg.sender, address(this), _amount), "transferFrom should success");

        lockingId = super._lock(_amount, _period, msg.sender,numerator,denominator);

        lockedTokens[lockingId] = _token;

        emit LockToken(lockingId,address(_token),numerator,denominator);
    }
}
