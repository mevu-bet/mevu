const Mevu = artifacts.require("../build/Mevu.sol");
const Events = artifacts.require("../build/Events.sol");
const EventsController = artifacts.require("../build/EventsController.sol");
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
const Web3 = require('web3');


contract('Mevu', function (accounts) {
    let mevu;
    let events;
    let eventsController;
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

    let teams = [web3.sha3('team1'), web3.sha3('team2')];
    let wagerAmount = 10000000000000000;
    let oraclePeriod = 1800;

    beforeEach('setup contract for each test', async function () {
        mevu = await Mevu.deployed();
        events = await Events.deployed();
        eventsController = await EventsController.deployed();
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

    // Lottery Entrance Requirements: Positive mvu balance, player rep, and oracle rep. Must have been an oracle in the last week.
    // Oracles 1, 2, 3, and 4 will fulfill this set of criteria and will enter the lottery.

    describe('verifying oracles -- ', function () {
        it("should let owner verify oracles", async function () {
            await oracleVerif.addVerifiedOracle(accounts[0], 55).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[1], 56).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[2], 57).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[3], 58).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[4], 59).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[19], 54).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[20], 53).should.be.fulfilled;
        });
    });
    describe('approving token transfers -- ', function () {
        it("should let anyone approve transfers from token contract", async function () {
            await mvuToken.approve(oraclesController.address, 5000000000).should.be.fulfilled;
            await mvuToken.transfer(accounts[1], 1000000000).should.be.fulfilled;
            await mvuToken.transfer(accounts[2], 1000000000).should.be.fulfilled;
            await mvuToken.transfer(accounts[3], 100000000).should.be.fulfilled;
            await mvuToken.transfer(accounts[4], 2000000).should.be.fulfilled;
            await mvuToken.transfer(accounts[19], 100000000).should.be.fulfilled;
            await mvuToken.transfer(accounts[20], 100000000).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, { from: accounts[1] }).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, { from: accounts[2] }).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, { from: accounts[3] }).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, { from: accounts[4] }).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, { from: accounts[19] }).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, { from: accounts[20] }).should.be.fulfilled;
        });
    });
    describe('making and updating events -- ', function () {
        it("should let oracles create events", async function () {
            await increaseTimeTo(latestTime() + 2160000); // Advance to near the end of the month
            await eventsController.makeEvent(web3.sha3("test_event2"),
                latestTime(),
                20,
                teams,
                false, { value: 10000 }).should.be.fulfilled;
            await eventsController.makeEvent(web3.sha3("test_event3"),
                latestTime() - 5,
                1,
                teams,
                false, { value: 10000 }).should.be.fulfilled;
            await eventsController.makeEvent(web3.sha3("test_event4"),
                latestTime(),
                10000,
                teams,
                false, { value: 10000 }).should.be.fulfilled;
            await eventsController.makeEvent(web3.sha3("test_event5"),
                latestTime(),
                4000,
                teams,
                false, { value: 10000 }).should.be.fulfilled;
        });
        it("should add created event to activeEvents array", async function () {
            let included = false;
            for (let i = 0; i < await events.getActiveEventsLength(); i++) {
                if (await events.getActiveEventId(i) == web3.sha3("test_event2")) {
                    included = true;
                }
            }
            included.should.equal(true);
        });
        it("should let owner set min oracle num", async function () {
            await admin.setMinOracleNum(web3.sha3("test_event2"), 3);
            await admin.setMinOracleNum(web3.sha3("test_event3"), 3);
            await admin.setMinOracleNum(web3.sha3("test_event4"), 2);
        });
        it('should prevent non-oracles from creating events', async function () {
            await eventsController.makeEvent(web3.sha3("test_event2"),
                1512519349,
                6000,
                teams,
                false, { from: accounts[5] }).should.be.rejectedWith(EVMRevert);
        });
    });
    describe('making wagers -- ', function () {
        it("it should let anyone make a wager", async function () {
            let balanceA = web3.eth.getBalance(accounts[0]).valueOf();
            await wagersController.makeWager(web3.sha3("wager1"), web3.sha3("test_event2"), wagerAmount, 100, 0, {
                value: wagerAmount,
                gasPrice: 2000000000
            }).should.be.fulfilled;
            let maker = await wagers.getMaker(web3.sha3("wager1"));
            maker.should.equal(accounts[0]);
            let newBalance = web3.eth.getBalance(accounts[0]).valueOf();
            let diff = balanceA - newBalance;
            diff.should.be.above(wagerAmount);
            diff.should.be.below(wagerAmount + wagerAmount / 10);

            await wagersController.makeWager(web3.sha3("wager2"), web3.sha3("test_event2"), wagerAmount, 100, 0, {
                from: accounts[2],
                value: wagerAmount
            }).should.be.fulfilled;

            // wager to cancel without being taken
            await wagersController.makeWager(web3.sha3("wager3"), web3.sha3("test_event2"), wagerAmount, 100, 0, {
                from: accounts[5],
                value: wagerAmount
            }).should.be.fulfilled;
            await wagersController.makeWager(web3.sha3("wager4"), web3.sha3("test_event2"), wagerAmount, 100, 0, {
                from: accounts[7],
                value: wagerAmount
            }).should.be.fulfilled;
            await wagersController.makeWager(web3.sha3("wager5"), web3.sha3("test_event5"), wagerAmount, 100, 0, {
                from: accounts[8],
                value: wagerAmount
            }).should.be.fulfilled;
            await wagersController.makeWager(web3.sha3("wager6"), web3.sha3("test_event4"), wagerAmount, 100, 0, {
                from: accounts[10],
                value: wagerAmount
            }).should.be.fulfilled;

            // Wager to let Oracles get player rep
            await wagersController.makeWager(web3.sha3("wager7"), web3.sha3("test_event2"), wagerAmount, 100, 0, {
                from: accounts[3],
                value: wagerAmount
            }).should.be.fulfilled;
        });
        it("should update rewards contract", async function () {
            let bal = await rewards.getEthBalance(accounts[0]).should.be.fulfilled;
            let uBal = await rewards.getUnlockedEthBalance(accounts[0]).should.be.fulfilled;
            uBal.valueOf().should.equal('0');
            bal.valueOf().should.equal('10000000000000000');
        });
        it("it should let anyone take a wager", async function () {
            await wagersController.takeWager(web3.sha3("wager1"), { from: accounts[1], value: wagerAmount }).should.be.fulfilled;
            let taker = await wagers.getTaker(web3.sha3("wager1"));
            taker.should.equal(accounts[1]);

            await wagersController.takeWager(web3.sha3("wager2"), { from: accounts[5], value: wagerAmount }).should.be.fulfilled;
            await wagersController.takeWager(web3.sha3("wager5"), { from: accounts[9], value: wagerAmount }).should.be.fulfilled;
            await wagersController.takeWager(web3.sha3("wager6"), { from: accounts[11], value: wagerAmount }).should.be.fulfilled;
            await wagersController.takeWager(web3.sha3("wager7"), { from: accounts[4], value: wagerAmount }).should.be.fulfilled;
        });
    });
    describe('updating events and settling wagers -- ', function () {
        it("should not be voteReady until its over", async function () {
            let voteReady = await events.getVoteReady(web3.sha3("test_event5"));
            voteReady.should.equal(false);
        });
        it("should not accept oracle votes before event is voteReady", async function () {
            await oraclesController.registerOracle(web3.sha3("test_event5"), 1, 1, { from: accounts[0] }).should.be.rejectedWith(EVMRevert);
        });
        it("should not accept bettor votes until event is over", async function () {
            await wagersController.submitVote(web3.sha3("wager1"), 0, { from: accounts[0] }).should.be.rejectedWith(EVMRevert);
        });
        it("should make a recently finished event voteReady", async function () {
            await increaseTimeTo(latestTime() + 21);

            let voteReady = await events.getVoteReady(web3.sha3("test_event2")).should.be.fulfilled;
            voteReady.should.equal(true);
            let locked = await events.getLocked(web3.sha3("test_event2")).should.be.fulfilled;
            locked.should.equal(false);
        });
        it("should let maker vote", async function () {
            await wagersController.submitVote(web3.sha3("wager1"), 0, { from: accounts[0] }).should.be.fulfilled;
            let vote = await wagers.getMakerWinVote(web3.sha3("wager1"));
            vote.valueOf().should.equal('0');

            await wagersController.submitVote(web3.sha3("wager2"), 0, { from: accounts[2], gasPrice: 2000000000 }).should.be.fulfilled;
            await wagersController.submitVote(web3.sha3("wager7"), 0, { from: accounts[3], gasPrice: 2000000000 }).should.be.fulfilled;

        });
        it("should prevent non-bettors from voting", async function () {
            await wagersController.submitVote(web3.sha3("wager1"), 0, { from: accounts[4] }).should.be.rejectedWith(EVMRevert);
        });
        it("should let taker vote and payout winner if they agree", async function () {
            let balanceA = web3.eth.getBalance(accounts[0]).valueOf();

            await wagersController.submitVote(web3.sha3("wager1"), 0, { from: accounts[1] }).should.be.fulfilled;
            let vote = await wagers.getTakerWinVote(web3.sha3("wager1"));
            vote.valueOf().should.equal('0');

            let newBalance = web3.eth.getBalance(accounts[0]);
            let diff = newBalance - balanceA;
            diff.should.be.within(19000000000000000, 21000000000000000);
        });
        it("should not have a winner chosen yet", async function () {
            let winner = await events.getWinner(web3.sha3("test_event2")).should.be.fulfilled;
            winner.valueOf().should.equal('0');
        });
        it("should accept oracle votes and tokens for verified oracles for voteReady event", async function () {
            await oraclesController.registerOracle(web3.sha3("test_event2"), 100000000, 0, { from: accounts[0] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event2"), 100000000, 0, { from: accounts[1] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event2"), 200000000, 0, { from: accounts[2] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event2"), 10000000,  0, { from: accounts[3] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event2"), 1000000,   0, { from: accounts[4] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event2"), 10,        0, { from: accounts[0] }).should.be.rejectedWith(EVMRevert);
        });
        it("should make a voteReady event locked after user finalizes", async function () {
            await increaseTimeTo(latestTime() + 1025 + oraclePeriod);
            await eventsController.finalizeEvent(web3.sha3("test_event2")).should.be.fulfilled;
            let locked = await events.getLocked(web3.sha3("test_event2"));
            locked.should.equal(true);

            await eventsController.finalizeEvent(web3.sha3("test_event3")).should.be.fulfilled;
            let locked3 = await events.getLocked(web3.sha3("test_event3")).should.be.fulfilled;
            locked3.should.equal(true);
        });
        it("should have a winner chosen now", async function () {
            let winner = await events.getWinner(web3.sha3("test_event2")).should.be.fulfilled;
            winner.valueOf().should.equal('0');
        });
        it("should let winner vote again after disagreement to claim win", async function () {
            let bal = web3.eth.getBalance(accounts[2]).valueOf();
            await wagersController.submitVote(web3.sha3("wager2"), 1, { from: accounts[2], gasPrice: 2000000000 }).should.be.fulfilled;
            let newBal = web3.eth.getBalance(accounts[2]).valueOf();
            let diff = newBal - bal;
            diff.valueOf().should.be.within(18400000000000000,19400000000000000);
        });
        it("should let oracles claim rewards", async function () {
            let oUnlMvuBal0 = await rewards.getUnlockedMvuBalance(accounts[0]);
            let oMvuBal0 = await rewards.getMvuBalance(accounts[0]);
            let rep0 = await rewards.getOracleRep(accounts[0]);
            let oUnlEthBal0 = await rewards.getUnlockedEthBalance(accounts[0]);

            oUnlMvuBal0.valueOf().should.equal('0');
            oMvuBal0.valueOf().should.equal('100000000');
            oUnlEthBal0.valueOf().should.equal('0');
            rep0.valueOf().should.equal('0');

            await oraclesController.claimReward(web3.sha3("test_event2")).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event2"), { from: accounts[1] }).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event2"), { from: accounts[2] }).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event2"), { from: accounts[3] }).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event2"), { from: accounts[4] }).should.be.fulfilled;
        });
    });
    describe('cleaning up finished events -- ', function () {
        it("should remove a finished event from activeEvents array", async function () {
            let deleted = true;
            for (let i = 0; i < await events.getActiveEventsLength(); i++) {
                if (await events.getActiveEventId(i) == web3.sha3("test_event2")) {
                    deleted = false;
                }
            }
            deleted.should.equal(true);
        });
    });
    describe('Testing lottery functions -- ', function () {
        it("should have built up a lottery pot", async function() {
            mevu.getLotteryPot().should.not.equal(0);
        });
        it("should allow oracles to enter the lottery", async function() {
            const shouldShowOracleInfo = false;
            for (let oracle = 1; oracle <= 4; oracle++) {
                if (shouldShowOracleInfo) {
                    console.log("Oracle Account #: " + oracle);
                    console.log("Last Oraclized: " + (await oracles.getLastEventOraclized(accounts[oracle])).valueOf());
                    console.log("Oracle Rep: " +     (await rewards.getOracleRep(accounts[oracle])).valueOf());
                    console.log("Player Rep: " +     (await rewards.getPlayerRep(accounts[oracle])).valueOf());
                    console.log("Balance:" +         (await mvuToken.balanceOf(accounts[oracle])).valueOf());
                }
                await mevu.enterLottery({ from: accounts[oracle] }).should.be.fulfilled;
            }
            let entrantCount = await mevu.getLotteryEntrantCount();
            console.log("Entrant Count: " + entrantCount.valueOf());
            entrantCount.valueOf().should.equal('4');
        });
        it("should not allow oracles to enter the lottery twice", async function() {
            await mevu.enterLottery({ from: accounts[1] }).should.be.rejectedWith(EVMRevert);
            await mevu.enterLottery({ from: accounts[2] }).should.be.rejectedWith(EVMRevert);
            await mevu.enterLottery({ from: accounts[3] }).should.be.rejectedWith(EVMRevert);
            await mevu.enterLottery({ from: accounts[4] }).should.be.rejectedWith(EVMRevert);
            let entrantCount = await mevu.getLotteryEntrantCount();
            entrantCount.valueOf().should.equal('4');
        });
        it("should not run the lottery early", async function() {
            await mevu.runLottery().should.be.rejectedWith(EVMRevert);
        });
        it("should run the lottery successfully", async function() {
            let balances = [0];

            await increaseTimeTo(latestTime() + 432000);

            for (let oracle = 1; oracle <= 4; oracle++) {
                balances.push(web3.eth.getBalance(accounts[oracle]).valueOf());
            }
            let pot = await mevu.getLotteryPot();
            console.log(`Lottery pot is ${pot}`);

            await mevu.runLottery().should.be.fulfilled;
            let randomNumber = await eventOccurred(mevu, "ReceivedRandomNumber", 60000);
            let newEntrantCount = await mevu.getLotteryEntrantCount();
            newEntrantCount.valueOf().should.equal('0');

            let foundWinner = false;
            for (let oracle = 1; oracle <= 4; oracle++) {
                let currentBalance = web3.eth.getBalance(accounts[oracle]).valueOf();
                if (currentBalance > balances[oracle]) {
                    foundWinner = true;
                    console.log(`Found winner (account #${oracle}). Had: ${balances[oracle]}, now has ${currentBalance}`);
                }
            }
            foundWinner.should.equal(true);
        });
        it("should not run the lottery too soon after the previous lottery", async function() {
            await mevu.runLottery().should.be.rejectedWith(EVMRevert);
        });
    });
    describe('Running lottery again', function() {
        it("should allow another event to be created", async function() {
            await eventsController.makeEvent(web3.sha3("test_event6"),
                latestTime() + 2582000,
                4000,
                teams,
                false, { value: 10000 }).should.be.fulfilled;
        });
        it("should allow a wager to be made", async function() {
            await wagersController.makeWager(web3.sha3("wager9"), web3.sha3("test_event6"), wagerAmount, 100, 0, {
                from: accounts[0],
                value: wagerAmount
            }).should.be.fulfilled;
        });
        it("should allow a wager to be taken", async function() {
            await wagersController.takeWager(web3.sha3("wager9"), { from: accounts[5], value: wagerAmount }).should.be.fulfilled;
        });
        it("should make a recently finished event voteReady", async function () {
            await increaseTimeTo(latestTime() + 2582000 + 4001);
            let voteReady = await events.getVoteReady(web3.sha3("test_event6")).should.be.fulfilled;
            voteReady.should.equal(true);
            let locked = await events.getLocked(web3.sha3("test_event6")).should.be.fulfilled;
            locked.should.equal(false);
        });
        it("should accept oracle votes and tokens for verified oracles for voteReady event", async function () {
            await oraclesController.registerOracle(web3.sha3("test_event6"), 100000000, 0, { from: accounts[0] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event6"), 100000000, 0, { from: accounts[1] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event6"), 200000000, 0, { from: accounts[2] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event6"), 10000000,  0, { from: accounts[3] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event6"), 500000,    0, { from: accounts[4] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.sha3("test_event6"), 10,        0, { from: accounts[0] }).should.be.rejectedWith(EVMRevert);
        });
        it("should make a voteReady event locked after user finalizes", async function () {
            await increaseTimeTo(latestTime() + oraclePeriod);
            await eventsController.finalizeEvent(web3.sha3("test_event6")).should.be.fulfilled;
            let locked = await events.getLocked(web3.sha3("test_event6"));
            locked.should.equal(true);
        });
        it("should have a winner chosen now", async function () {
            let winner = await events.getWinner(web3.sha3("test_event6")).should.be.fulfilled;
            winner.valueOf().should.equal('0');
        });
        it("should let winner vote again after disagreement to claim win", async function () {
            await wagersController.submitVote(web3.sha3("wager9"), 1, { from: accounts[0], gasPrice: 2000000000 }).should.be.fulfilled;
        });
        it("should let oracles claim rewards", async function () {
            await oraclesController.claimReward(web3.sha3("test_event6")).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event6"), { from: accounts[1] }).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event6"), { from: accounts[2] }).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event6"), { from: accounts[3] }).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event6"), { from: accounts[4] }).should.be.fulfilled;
        });
        it("should have built up a new lottery pot", async function() {
            mevu.getLotteryPot().should.not.equal(0);
        });
        it("should allow oracles to enter the lottery again", async function() {
            const shouldShowOracleInfo = false;
            for (let oracle = 1; oracle <= 4; oracle++) {
                if (shouldShowOracleInfo) {
                    console.log("Oracle Account #: " + oracle);
                    console.log("Last Oraclized: " + (await oracles.getLastEventOraclized(accounts[oracle])).valueOf());
                    console.log("Oracle Rep: " +     (await rewards.getOracleRep(accounts[oracle])).valueOf());
                    console.log("Player Rep: " +     (await rewards.getPlayerRep(accounts[oracle])).valueOf());
                    console.log("Balance:" +         (await mvuToken.balanceOf(accounts[oracle])).valueOf());
                }
                await mevu.enterLottery({ from: accounts[oracle] }).should.be.fulfilled;
            }
            let entrantCount = await mevu.getLotteryEntrantCount();
            console.log("Entrant Count: " + entrantCount.valueOf());
            entrantCount.valueOf().should.equal('4');
        });
        it("should not allow oracles to enter the lottery twice", async function() {
            await mevu.enterLottery({ from: accounts[1] }).should.be.rejectedWith(EVMRevert);
            await mevu.enterLottery({ from: accounts[2] }).should.be.rejectedWith(EVMRevert);
            await mevu.enterLottery({ from: accounts[3] }).should.be.rejectedWith(EVMRevert);
            await mevu.enterLottery({ from: accounts[4] }).should.be.rejectedWith(EVMRevert);
            let entrantCount = await mevu.getLotteryEntrantCount();
            entrantCount.valueOf().should.equal('4');
        });
        it("should run the lottery successfully, again", async function() {
            let balances = [0];

            await increaseTimeTo(latestTime() + 10000);

            for (let oracle = 1; oracle <= 4; oracle++) {
                balances.push(web3.eth.getBalance(accounts[oracle]).valueOf());
            }
            let pot = await mevu.getLotteryPot();
            console.log(`Lottery pot is ${pot}`);

            await mevu.runLottery().should.be.fulfilled;
            let randomNumber = await eventOccurred(mevu, "ReceivedRandomNumber", 60000);
            let newEntrantCount = await mevu.getLotteryEntrantCount();
            newEntrantCount.valueOf().should.equal('0');

            let foundWinner = false;
            for (let oracle = 1; oracle <= 4; oracle++) {
                let currentBalance = web3.eth.getBalance(accounts[oracle]).valueOf();
                if (currentBalance > balances[oracle]) {
                    foundWinner = true;
                    console.log(`Found winner (account #${oracle}). Had: ${balances[oracle]}, now has ${currentBalance}`);
                }
            }
            foundWinner.should.equal(true);
        });
        it("should not run the lottery too soon after the previous lottery", async function() {
            await mevu.runLottery().should.be.rejectedWith(EVMRevert);
        });
    });

    function eventOccurred(contract, eventName, timeout) {
        return new Promise((resolve, reject) => {
            let event = contract[eventName]({});
            event.watch((error, evt) => {
                event.stopWatching();
                resolve(evt);
            });
            setTimeout(() => reject(`Timed out waiting for event: ${eventName}`), timeout);
        });
    }
});