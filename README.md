# meVu Contracts

A network of smart-contracts deployed to the EVM to facilitate a system of peer-to-peer betting called [Mevu][mevu].

This code is still in active development and is not yet intended for a main net release.


## Contracts

Please see the [contracts/](contracts) directory.


## Develop

* Contracts are written in [Solidity][solidity] and tested using [Truffle][truffle] and [ganache-cli][ganache-cli] and
the [Oraclize][oraclize] [ethereum-bridge][ethereum-bridge].


### Dependencies

https://github.com/OpenZeppelin/zeppelin-solidity

https://github.com/oraclize/ethereum-api

If testing :

https://github.com/trufflesuite/ganache-cli

https://github.com/oraclize/ethereum-bridge


### Test

```bash
truffle test
```


## Code

### Admin Functions

**setCallbackGasLimit**
```cs
function setCallbackGasLimit (uint newLimit) external onlyAuth
```
Sets the gas limit for the callbcak transaction initiated by the oraclizeAPI.


**setCallbackInterval**
```cs
function setCallbackInterval(uint newInterval) external onlyAuth
```
Sets the interval (seconds) between the callback loops which update events.


**setMinOracleStake**
```cs
function setMinOracleStake (uint newMin) external onlyAuth
```
Sets the minimum stake required for a user to oraclize an event.


**setMinOracleNum**
```cs
function setMinOracleNum (bytes32 eventId, uint min) external onlyAuth
```
Sets the minimum number of Oracles required to satisfactorily determine the winner of a particular event.


**setMinWagerAmount**
```cs
function setMinWagerAmount(uint256 minWager) external onlyAuth
```
Sets the minimum amount of ETH a player is allowed to make a bet with.


**setMaxOracleInterval**
```cs
function setMaxOracleInterval (uint max) external onlyAuth
```
Set the maximum amount of time (seconds) allowable between 
oraclizations for a user to be eligible to win the monthly lottery.


**setOracleRepPenalty**
```cs
function setOracleRepPenalty (int penalty) external onlyAuth
```
Set the reputation penalty incurred by an Oracle who has voted against consensus.


**setOracleRepReward**
```cs
function setOracleRepReward (int reward) external onlyAuth
```
Set the reputation reward awarded to an Oracle who has voted with consensus.


**setPlayerAgreeRepReward**
```cs
function setPlayerAgreeRepReward (int reward) external onlyAuth
```
Set the reputation reward awarded to a player who has successfully settled their bet without requiring Oracles.


**setPlayerDisagreeRepPenalty**
```cs
function setPlayerDisagreeRepPenalty (int penalty) external onlyAuth
```
Set the reputation penalty incurred by a player who disputed an event outcome and was found to be aganist Oracle consensus.


**getCallbackGasLimit**
```cs
function getCallbackGasLimit() external view returns (uint)
```
Returns the gas limit for oraclize callbacks.


**getCallbackInterval**
```cs
function getCallbackInterval() external view returns (uint)
```
Returns the interval (seconds) between oraclize callback loops.


**getMaxOracleInterval**
```cs
function getMaxOracleInterval() external view returns (uint)
```
Returns the max alllowable interval (seconds) between oraclizations for an oracle to be eligible to win the monthly lottery.


**getMinOracleNum**
```cs
function getMinOracleNum (bytes32 eventId) external view returns (uint)
```
Returns minimum number of Oracles required to settle a specific event.


**getMinOracleStake**
```cs
function getMinOracleStake () external view returns (uint)
```
Returns minimum stake required to register as an oracle for an event.


**getMinWagerAmount**
```cs
function getMinWagerAmount() external view returns (uint)
```
Returns minimum amount of ETH required to bet with.


**getOracleRepPenalty**
```cs
function getOracleRepPenalty () external view returns (int)
```
Returns rep penalty incurred by Oracle for reporting against consensus.


**getOracleRepReward**
```cs
function getOracleRepReward () external view returns (int)
```
Returns rep reward awarded to an Oracle for reporting with consensus.


**getPlayerAgreeRepReward**
```cs
function getPlayerAgreeRepReward () external view returns (int)
```
Returns rep reward awarded to a player for settling a bet without requiring Oracles.


**getPlayerDisagreeRepPenalty**
```cs
function getPlayerDisagreeRepPenalty () external view returns (int)
```
Returns rep penalty incurred by a player who diputed an outcome and was found to be against Oracle consensus.


### AuthorityGranter Functions


**grantAuthority**
```cs
function grantAuthority (address nowAuthorized) external onlyOwner
```
Grants an address authority by adding it to the isAuthorized mapping.


**removeAuthority**
```cs
function removeAuthority (address unauthorized) external onlyOwner
```
Takes an address' authority by removing it from the isAuthorized mapping.



## License

MIT License

[mevu]: https://mevu.bet
[solidity]: https://solidity.readthedocs.io/en/develop/
[truffle]: http://truffleframework.com/
[ganache-cli]: https://github.com/trufflesuite/ganache-cli
[openzeppelin]: https://openzeppelin.org
[oraclize]: http://www.oraclize.it/
[ethereum-bridge]: https://github.com/oraclize/ethereum-bridge