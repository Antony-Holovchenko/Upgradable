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
        _updateReward(address(0));
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

    /**
     * @dev Call this function to stake tokens amount.
     * @param _amount - value of the tokens to stake.
     */ 
    function stake(uint256 _amount, address _staker) external {
        require(_amount > 0, "Amount couldn't be 0");
        
        _updateReward(_staker);
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        totalSupply += _amount;
        stakedUserAmount[msg.sender] += _amount;
    }

    /**
     * @dev Call this function to withdraw staked tokens amount.
     * @param _amount - value of the tokens to withdraw.
     */
    function withdraw(uint256 _amount, address _staker) external {
        require(_amount > 0, "Amount couldn't be 0");
        require(stakedUserAmount[msg.sender] >= _amount, "Insufficient balance");

        _updateReward(_staker);
        totalSupply -= _amount;
        stakedUserAmount[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    /**
     * @dev Call to return the amount of earned reward tokens for the account.
     * The earned amount is calculated by the next formula: amount of all staked user tokens *
     * (reward per token - user reward per token paid) + previous user rewards.
     * 
     * @param _staker - account which earned rewards.
     */
    function earn(address _staker) public view returns(uint256 _amount) {
        uint256 stakedAmount = stakedUserAmount[_staker];
        uint256 userRewardPerToken = userRewardPerTokenPaid[_staker];

        return (stakedAmount *  (calculateRewardPerToken() - userRewardPerToken)) / 1e18 + rewards[_staker];
    }
 
    // stakers can claim their rewards
    function claimReward(address _staker) external {
        _updateReward(_staker);

        uint256 reward = rewards[_staker];
        if(reward > 0) {
          rewards[_staker] = 0;
          rewardsToken.transfer(_staker, reward);
        }
    }

    /**
     * @dev Calculate the current reward per token. 
     */
    function calculateRewardPerToken() public view returns(uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (
            rewardRate * (lastTimeRewardApplicable() - rewardRateUpdatedAt) * 1e18
        ) / totalSupply;
    }
    
    /**
     * @dev Return the timestamp, when the last reward is still available.
     */
    function lastTimeRewardApplicable() public view returns(uint256){
        return _min(block.timestamp, rewardFinishAt);
    }

    /**
     * @dev Return minimum number between 2 values. 
     * @param x - 1st number 
     * @param y - 2nd number
     */
    function _min(uint256 x, uint256 y) private pure returns(uint256) {
        return x < y ? x : y;
    }

    /**
     * @dev Update the reward for a specific staker.
     * @param _staker - account which balance should be updated.
     */
    function _updateReward(address _staker) private {
        // Update the rewardPerToken for a current value
        rewardPerTokenStored = calculateRewardPerToken();
        // if the reward is still ongoing, the "lastTimeRewardApplicable()" 
        // will return the current block.timestamp, and if the reward is elapsed
        // the "lastTimeRewardApplicable()" will return the time when it is expired
        rewardRateUpdatedAt = lastTimeRewardApplicable();
        if(_staker != address(0)) {
            rewards[_staker] = earn(_staker);
            userRewardPerTokenPaid[_staker] = rewardPerTokenStored;
        }
    }

}