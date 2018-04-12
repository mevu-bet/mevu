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

    it('should let player make bet, disagree, and abort', async function() {
      let initialbalance1 = Number(web3.eth.getBalance(accounts[3]).valueOf());
      let initialbalance2 = Number(web3.eth.getBalance(accounts[4]).valueOf());
      await eventController.makeEvent(web3.sha3('event2'),
                                      now,
                                      1,
                                      web3.sha3('team1'),
                                      web3.sha3('team2'),
	                              {value: 10000}).should.be.fulfilled;
      await wagersController.makeWager(web3.sha3('wager2'),
                                        web3.sha3('event2'),
	                                wagerAmount,
                                        100,
                                        1,
                                        {
					                                from: accounts[3],
                                          value: wagerAmount,
					                                gasPrice: testGasPrice
                                        }).should.be.fulfilled;
      await wagersController.takeWager(web3.sha3('wager2'),
                                        {
                                          from: accounts[4],
                                          value: wagerAmount,
					                                gasPrice: testGasPrice
                                        }).should.be.fulfilled;


      await increaseTimeTo(latestTime() + 2);
      let newbalance1 = Number(web3.eth.getBalance(accounts[3]).valueOf());
      let newbalance2 = Number(web3.eth.getBalance(accounts[4]).valueOf());
      let diff1 = initialbalance1-newbalance1;
      let diff2 = initialbalance2-newbalance2;
      diff1.should.be.above(wagerAmount);
      diff1.should.be.below(wagerAmount+gasAllowance);
      diff2.should.be.above(wagerAmount);
      diff2.should.be.below(wagerAmount+gasAllowance);
      await increaseTimeTo(latestTime() + 2);
      let voteReady = await events.getVoteReady(web3.sha3("event2"));
      voteReady.should.equal(true);
      await wagersController.submitVote(web3.sha3('wager2'), 1, { from: accounts[3], gasPrice: testGasPrice }).should.be.fulfilled;
      let finished = await mevu.getContractPaused();
      finished.should.equal(false);
      await wagersController.submitVote(web3.sha3('wager2'), 2, { from: accounts[4], gasPrice: testGasPrice }).should.be.fulfilled;
      let makerWin = await wagers.getMakerWinVote(web3.sha3("wager2"));
      let takerWin = await wagers.getTakerWinVote(web3.sha3("wager2"));
      makerWin.valueOf().should.equal('1');
      takerWin.valueOf().should.equal('2');
      await increaseTimeTo(latestTime() + 1801);
      await eventsController.finalizeEvent(web3.sha3('event2'));
      await wagersController.submitVote(web3.sha3('wager2'), 1, { from: accounts[3], gasPrice: testGasPrice }).should.be.fulfilled;
      let unlockedBalance1 = Number(rewards.getUnlockedEthBalance(accounts[3]).valueOf());
      let unlockedBalance2 = Number(rewards.getUnlockedEthBalance(accounts[4]).valueOf());
      unlockedBalance1.should.be.above((wagerAmount)-gasAllowance);
      unlockedBalance1.should.be.below((wagerAmount));
      unlockedBalance2.should.be.below((wagerAmount)-gasAllowance);
      unlockedBalance2.should.be.above((wagerAmount));
    });

    it('should let player make bet, oracle votes, bet is settled', async function() {
      let initialbalance1 = Number(web3.eth.getBalance(accounts[5]).valueOf());
      let initialbalance2 = Number(web3.eth.getBalance(accounts[6]).valueOf());
      await eventController.makeEvent(web3.sha3('event3'),
                                      now,
                                      1,
                                      web3.sha3('team1'),
                                      web3.sha3('team2'),
	                              {value: 10000}).should.be.fulfilled;
      await wagersController.makeWager(web3.sha3('wager3'),
                                        web3.sha3('event3'),
	                                wagerAmount,
                                        100,
                                        1,
                                        {
					                                from: accounts[5],
                                          value: wagerAmount,
					                                gasPrice: testGasPrice
                                        }).should.be.fulfilled;
      await wagersController.takeWager(web3.sha3('wager3'),
                                        {
                                          from: accounts[6],
                                          value: wagerAmount,
					                                gasPrice: testGasPrice
                                        }).should.be.fulfilled;


      await increaseTimeTo(latestTime() + 2);
      let newbalance1 = Number(web3.eth.getBalance(accounts[5]).valueOf());
      let newbalance2 = Number(web3.eth.getBalance(accounts[6]).valueOf());
      let diff1 = initialbalance1-newbalance1;
      let diff2 = initialbalance2-newbalance2;
      diff1.should.be.above(wagerAmount);
      diff1.should.be.below(wagerAmount+gasAllowance);
      diff2.should.be.above(wagerAmount);
      diff2.should.be.below(wagerAmount+gasAllowance);
      await increaseTimeTo(latestTime() + 2);
      let voteReady = await events.getVoteReady(web3.sha3("event3"));
      voteReady.should.equal(true);
      await wagersController.submitVote(web3.sha3('wager3'), 1, { from: accounts[5], gasPrice: testGasPrice }).should.be.fulfilled;
      let finished = await mevu.getContractPaused();
      finished.should.equal(false);
      await wagersController.submitVote(web3.sha3('wager3'), 2, { from: accounts[6], gasPrice: testGasPrice }).should.be.fulfilled;
      let makerWin = await wagers.getMakerWinVote(web3.sha3("wager3"));
      let takerWin = await wagers.getTakerWinVote(web3.sha3("wager3"));
      makerWin.valueOf().should.equal('1');
      takerWin.valueOf().should.equal('2');
      await oraclesController.registerOracle(web3.sha3("event3"), 1, 1, { from: accounts[0] });
      await eventsController.finalizeEvent(web3.sha3('event3'));
      await wagersController.submitVote(web3.sha3('wager3'), 1, { from: accounts[5], gasPrice: testGasPrice }).should.be.fulfilled;
      // TODO: check payout for winner
      let finalbalance1 = Number(web3.eth.getBalance(accounts[5]).valueOf());
      let finalbalance2 = Number(web3.eth.getBalance(accounts[6]).valueOf());
      let finaldiff1 = finalbalance1-newbalance1;
      let finaldiff2 = newbalance2-finalbalance2;
      finaldiff1.should.be.above((2*wagerAmount)-(wagerAmount/50)-gasAllowance);
      finaldiff1.should.be.below((2*wagerAmount)-(wagerAmount/50));
      finaldiff2.should.be.below(gasAllowance);
      finaldiff2.should.be.above(0);
    });

    it('should let player make bet, not taken, and cancel', async function() {
      let initialbalance1 = Number(web3.eth.getBalance(accounts[7]).valueOf());
      await eventController.makeEvent(web3.sha3('event3'),
                                      now,
                                      1,
                                      web3.sha3('team1'),
                                      web3.sha3('team2'),
	                              {value: 10000}).should.be.fulfilled;
      await wagersController.makeWager(web3.sha3('wager3'),
                                        web3.sha3('event3'),
	                                wagerAmount,
                                        100,
                                        1,
                                        {
					                                from: accounts[7],
                                          value: wagerAmount,
					                                gasPrice: testGasPrice
                                        }).should.be.fulfilled;
    await increaseTimeTo(latestTime() + 100);
    await cancelController.cancelWagerStandard(web3.sha3('event4'), true);
    // TODO: Check refund
  });


  it('should let player make bet, loser doesnt report', async function() {
    let initialbalance1 = Number(web3.eth.getBalance(accounts[9]).valueOf());
    let initialbalance2 = Number(web3.eth.getBalance(accounts[10]).valueOf());
    await eventController.makeEvent(web3.sha3('event6'),
                                    now,
                                    1,
                                    web3.sha3('team1'),
                                    web3.sha3('team2'),
                              {value: 10000}).should.be.fulfilled;
    await wagersController.makeWager(web3.sha3('wager6'),
                                      web3.sha3('event6'),
                                wagerAmount,
                                      100,
                                      1,
                                      {
                                        from: accounts[9],
                                        value: wagerAmount,
                                        gasPrice: testGasPrice
                                      }).should.be.fulfilled;
    await wagersController.takeWager(web3.sha3('wager6'),
                                      {
                                        from: accounts[10],
                                        value: wagerAmount,
                                        gasPrice: testGasPrice
                                      }).should.be.fulfilled;


    await increaseTimeTo(latestTime() + 2);
    let newbalance1 = Number(web3.eth.getBalance(accounts[9]).valueOf());
    let newbalance2 = Number(web3.eth.getBalance(accounts[10]).valueOf());
    let diff1 = initialbalance1-newbalance1;
    let diff2 = initialbalance2-newbalance2;
    diff1.should.be.above(wagerAmount);
    diff1.should.be.below(wagerAmount+gasAllowance);
    diff2.should.be.above(wagerAmount);
    diff2.should.be.below(wagerAmount+gasAllowance);
    await increaseTimeTo(latestTime() + 2);
    let voteReady = await events.getVoteReady(web3.sha3("event6"));
    voteReady.should.equal(true);
    await wagersController.submitVote(web3.sha3('wager6'), 1, { from: accounts[5], gasPrice: testGasPrice }).should.be.fulfilled;
    let finished = await mevu.getContractPaused();
    finished.should.equal(false);
    await increaseTimeTo(latestTime() + 1801);
    await eventsController.finalizeEvent(web3.sha3('event6'));
    await wagersController.submitVote(web3.sha3('wager6'), 1, { from: accounts[1], gasPrice: testGasPrice }).should.be.fulfilled;
    let unlockedBalance1 = Number(rewards.getUnlockedEthBalance(accounts[9]).valueOf());
    let unlockedBalance2 = Number(rewards.getUnlockedEthBalance(accounts[10]).valueOf());
    unlockedBalance1.should.be.above((wagerAmount)-gasAllowance);
    unlockedBalance1.should.be.below((wagerAmount));
    unlockedBalance2.should.be.below((wagerAmount)-gasAllowance);
    unlockedBalance2.should.be.above((wagerAmount));
  });

});
