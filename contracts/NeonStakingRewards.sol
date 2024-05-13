// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NeonToken.sol";

contract NeonStakingRewards is Initializable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable stakingToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    NeonToken public immutable rewardsToken;

    // var-s that keep track users rewards
    uint public rewardDuration; // duration of the rewarding
    uint public rewardFinishAt; // when a rewarding time is finish
    uint public rewardRateUpdatedAt; // when a rewardRate was updated
    uint public rewardRate; // a reward earned by user per second
    uint public rewardPerTokenStored;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    // var-s that keep track total supply of the staked token, 
    // and amount of staked token per user
    uint public totalSupply;
    mapping(address => uint) public stakedUserAmount;

    function initialize() external initializer{
        __Ownable_init(msg.sender);
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = NeonToken(_rewardsToken);
    }

   
    /**
     * @dev Set up a rewards duration. Only owner can call this function.
     * @param _duration  - period during which rewards can be earned.
     */
    function setRewardDuration(uint256 _duration) external onlyOwner {
        // make sure that owner can update reward duration, only when the previous period is finished
        require(rewardFinishAt < block.timestamp, "Rewards time isn't finished yet");
        rewardDuration = _duration;
    }

    /**
     * @dev Set up a reward amount. Function will send a reward tokens into
     * this contract, and set a reward rate. Only owner can call this function.
     * @param _amount - amount of tokens that will be used for a reward.
     */
    function setRewardAmount(uint256 _amount) external onlyOwner {
        // checking if the rewardDuration already expired, or not started
        if(block.timestamp > rewardFinishAt) { 
            rewardRate = _amount / rewardDuration;
        } else { // means that rewards duration is not finished yet --> we need 1st calculate the amount of the remaining rewards, 2nd add remaining amount to the amount we set in parameter to set up a reward rate
            uint remainingRewards = rewardRate * (rewardFinishAt - block.timestamp); // Mul rewardRate by the time until the rewards ends(finishAt - current time)
            rewardRate = (remainingRewards + _amount) / rewardDuration;

            require(rewardRate > 0, "Reward rate is 0");
            //checking that it is enough reward token in this contract, to pay rewards
            require(rewardRate * rewardDuration <= rewardsToken.balanceOf(address(this)), "Reward amount > than balance"); 
        
            rewardFinishAt = block.timestamp + rewardDuration;
            rewardRateUpdatedAt = block.timestamp;
        }
    }

    // user can stake token amount 
    function stake(uint256 _amount) external {

    }

    // user can withdraw his staked token amount
    function withdraw(uint256 _amount) external {

    }

    // function that is return the amount of earned reward tokens for the account
    function earn(address _staker) external view returns(uint256 _amount) {

    }
 
    // stakers can claim their rewards
    function claimReward() external {

    }

}