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

truffle test


## License

MIT License

[mevu]: https://mevu.bet
[solidity]: https://solidity.readthedocs.io/en/develop/
[truffle]: http://truffleframework.com/
[ganache-cli]: https://github.com/trufflesuite/ganache-cli
[openzeppelin]: https://openzeppelin.org
[oraclize]: http://www.oraclize.it/
[ethereum-bridge]: https://github.com/oraclize/ethereum-bridge