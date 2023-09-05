// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {ERC20} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

interface IStandardToken {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function withdrawEther() external;
}

contract Stakings is ERC20{
    IStandardToken Stoken;

    struct Staking {
        uint valStaked;
        uint timeStaked;
    }

    uint public stakeReward = 1;
    mapping (address => Staking) public stakeInfo;

    event Staked(uint totalStaked, uint time);
    event Unstaked(uint amount, uint totalStaked, uint time, uint reward);
    event Claimed(uint time, uint reward);

    constructor(address _Stoken) ERC20("Reward Token", "RT"){
        Stoken = IStandardToken(_Stoken);
    }

    function Stake(uint amount) external {
        uint balance = Stoken.balanceOf(msg.sender);
        require (balance >= amount, "Insufficient Balance");
        bool status = Stoken.transferFrom(msg.sender, address(this), amount);
        require (status == true, "Transfer Failed");
        Staking storage _user = stakeInfo[msg.sender];
        _user.valStaked += amount;
        _user.timeStaked = block.timestamp;
        emit Staked(_user.valStaked, block.timestamp);
    }

    fallback () external payable {}
    receive () external payable {}

    function getStakeAmount(address staker) public view returns (uint _staked) {
        Staking storage _user = stakeInfo[staker];
        _staked = _user.valStaked;
    }

    function calculateReward(address user) public view returns (uint256) {
        Staking storage _user = stakeInfo[user];
        uint256 stakingTime = (block.timestamp - _user.timeStaked) / 30;
        return _user.valStaked * stakingTime * stakeReward / 100; 
    }

    function Unstake(uint amount) external {
        Staking storage _user = stakeInfo[msg.sender];
        uint totalStaked = getStakeAmount(msg.sender);
        require(totalStaked >= amount, "insufficient amount");
        uint reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards");
        _user.timeStaked = block.timestamp;
        _mint(msg.sender, reward);
        _user.valStaked -= amount;
        Stoken.transfer(msg.sender, amount);
        emit Unstaked(amount, totalStaked, block.timestamp, reward);
    }

    function claimReward() public {
        Staking storage _user = stakeInfo[msg.sender];
        uint reward = calculateReward(msg.sender);
        require(reward > 0, "No reward to claim");
        _user.timeStaked = block.timestamp;
        _mint(msg.sender, reward);
        emit Claimed(block.timestamp, reward);
    } 

    function withdrawEther() external {
        Stoken.withdrawEther();
        payable(msg.sender).transfer(address(this).balance);
    }
}
