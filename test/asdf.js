const Mevu = artifacts.require("../build/Mevu.sol");
const Events = artifacts.require("../build/Events.sol");
const EventsController = artifacts.require("..build/EventsController.sol");
const Admin = artifacts.require("../build/Admin.sol");
const Wagers = artifacts.require("../build/Wagers.sol");
const WagersController = artifacts.require("../build/WagersController.sol");
const CustomWagers = artifacts.require("../build/CustomWagers.sol");
const CustomWagersController = artifacts.require("../build/CustomWagersController.sol");
const CancelController = artifacts.require("../build/CancelController.sol");
const Rewards = artifacts.require("../build/Rewards.sol");
const Oracles = artifacts.require("../build/Oracles.sol");
const OraclesController = artifacts.require("../build/OraclesController.sol");
const OracleVerifier = artifacts.require("../build/OracleVerifier.sol");
const MvuToken = artifacts.require("../build/MvuToken.sol");


import ether from './helpers/ether';
import { advanceBlock } from './helpers/advanceToBlock';
import { increaseTimeTo, duration } from './helpers/increaseTime';
import latestTime from './helpers/latestTime';
import EVMRevert from './helpers/EVMRevert';

const assertRevert = require('./helpers/assertRevert.js');

const BigNumber = require('bignumber.js');
const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();


contract('Player-Standard', function (accounts) {
  let mevu;
  let events;
  let eventController;
  let admin;
  let rewards;
  let oracles;
  let oraclesController;
  let wagers;
  let wagersController;
  let customWagers;
  let customWagersController;
  let cancelController;
  let oracleVerif;
  let mvuToken;
  let initialFund = 100000000000000000;
  let wagerAmount = 10000000000000000;
  let zeroAddress = '0x0000000000000000000000000000000000000000';
  let now = new Date().getTime()/1000;
  let balance1;
  let balance2;
  let balance3;
  let gasAllowance = wagerAmount/10;
  let testGasPrice = 2000000000;

  beforeEach('setup contract for each test', async function () {
    mevu = await Mevu.deployed();
    events = await Events.deployed();
    eventController = await EventsController.deployed();
    admin = await Admin.deployed();
    wagers = await Wagers.deployed();
    wagersController = await WagersController.deployed();
    customWagers = await CustomWagers.deployed();
    customWagersController = await CustomWagersController.deployed();
    cancelController = await CancelController.deployed();
    oracleVerif = await OracleVerifier.deployed();
    rewards = await Rewards.deployed();
    oracles = await Oracles.deployed();
    oraclesController = await OraclesController.deployed();
    mvuToken = await MvuToken.deployed();
  });


  describe('Case 1', function () {
    it('should verity oracles', async function() {
      await oracleVerif.addVerifiedOracle(accounts[0], 5555555555).should.be.fulfilled
    });
	  
    it('should let player make bet, report outcome and payout', async function() {
      let initialbalance1 = Number(web3.eth.getBalance(accounts[1]).valueOf());
      let initialbalance2 = Number(web3.eth.getBalance(accounts[2]).valueOf());
      await eventController.makeEvent(web3.sha3('event1'),
                                      now,
                                      1,
                                      web3.sha3('team1'),
                                      web3.sha3('team2'),
	                              {value: 10000}).should.be.fulfilled;
      await wagersController.makeWager(web3.sha3('wager1'),
                                        web3.sha3('event1'),
	                                wagerAmount,
                                        100,
                                        1,
                                        {
					  from: accounts[1],	
                                          value: wagerAmount,
					  gasPrice: testGasPrice	
                                        }).should.be.fulfilled;
      await wagersController.takeWager(web3.sha3('wager1'),
                                        {
                                          from: accounts[2],
                                          value: wagerAmount,
					  gasPrice: testGasPrice	
                                        }).should.be.fulfilled;


      await increaseTimeTo(latestTime() + 2);
      let newbalance1 = Number(web3.eth.getBalance(accounts[1]).valueOf());
      let newbalance2 = Number(web3.eth.getBalance(accounts[2]).valueOf());
      let diff1 = initialbalance1-newbalance1;
      let diff2 = initialbalance2-newbalance2;
      diff1.should.be.above(wagerAmount);
      diff1.should.be.below(wagerAmount+gasAllowance);
      diff2.should.be.above(wagerAmount);
      diff2.should.be.below(wagerAmount+gasAllowance);
      
      await increaseTimeTo(latestTime() + 2);
      let voteReady = await events.getVoteReady(web3.sha3("event1"));
      voteReady.should.equal(true);
      await wagersController.submitVote(web3.sha3('wager1'), 1, { from: accounts[1], gasPrice: testGasPrice }).should.be.fulfilled;
      let finished = await mevu.getContractPaused();
      finished.should.equal(false);  
      await wagersController.submitVote(web3.sha3('wager1'), 1, { from: accounts[2], gasPrice: testGasPrice }).should.be.fulfilled;
      let makerWin = await wagers.getMakerWinVote(web3.sha3("wager1"));
      let takerWin = await wagers.getTakerWinVote(web3.sha3("wager1"));
      makerWin.valueOf().should.equal('1');
      takerWin.valueOf().should.equal('1');
      let finalbalance1 = Number(web3.eth.getBalance(accounts[1]).valueOf());
      let finalbalance2 = Number(web3.eth.getBalance(accounts[2]).valueOf());	    
      let finaldiff1 = finalbalance1-newbalance1;
      let finaldiff2 = newbalance2-finalbalance2;
      finaldiff1.should.be.above((2*wagerAmount)-(wagerAmount/50)-gasAllowance);
      finaldiff1.should.be.below((2*wagerAmount)-(wagerAmount/50));
      finaldiff2.should.be.below(gasAllowance);
      finaldiff2.should.be.above(0);	    
    });

  });

});


