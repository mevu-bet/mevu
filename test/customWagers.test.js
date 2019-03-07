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
    let initialFund = 100000000000000000;
    let wagerAmount = 10000000000000000;
    let zeroAddress = '0x0000000000000000000000000000000000000000';
    let testGasPrice = 2000000000;
    let oraclePeriod = 1800;

    let teams = [web3.sha3('team1'),
    web3.sha3('team2')];

    let balanceA;
    let balanceB;
    let balanceC;

    let afterEventFinished = 1518839239;

    before(async function () {
        // Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
        await advanceBlock();
        // web3.setProvider(new Web3.providers.WebsocketProvider('ws://localhost:8545'));
    });

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

    describe('setting contracts address & ownership -- ', function () {
        it("should let owner set MvuToken address", async function () {
            await oraclesController.setMvuTokenContract(mvuToken.address).should.be.fulfilled;
        });

        it("should prevent non-owners from setting any addresses", async function () {
            await oraclesController.setMvuTokenContract(mvuToken.address, { from: accounts[1] }).should.be.rejectedWith(EVMRevert);
            await mevu.setRewardsContract(rewards.address, { from: accounts[1] }).should.be.rejectedWith(EVMRevert);
            await cancelController.setMevuContract(mevu.address, { from: accounts[1] }).should.be.rejectedWith(EVMRevert);
        });

    });



    describe('custom wager creation and settlement -- ', function () {

        it("it should let anyone make a custom wager with no judge", async function () {
            let balanceA = web3.eth.getBalance(accounts[0]).valueOf();
            await customWagersController.makeWager(web3.sha3("wager1"), latestTime() + 10, latestTime() + 10000, 1, wagerAmount, 100, { value: wagerAmount }).should.be.fulfilled;
            let maker = await customWagers.getMaker(web3.sha3("wager1"));
            maker.should.equal(accounts[0]);
            let newBalance = web3.eth.getBalance(accounts[0]).valueOf();
            let diff = balanceA - newBalance;
            diff.should.be.above(wagerAmount);

            await customWagersController.makeWager(web3.sha3("wager2"), latestTime() + 20, latestTime() + 10000, 1, wagerAmount, 100, { from: accounts[6], value: wagerAmount }).should.be.fulfilled;

            //await wagersController.makeWager(web3.sha3("wager2") , 10000000000000000, web3.sha3("test_event2"), 100, 1, {from:accounts[2], value:10000000000000000}).should.be.fulfilled;
        });

        it("should let the maker assign a judge", async function () {
            await customWagersController.addJudge(web3.sha3("wager1"), accounts[1]).should.be.fulfilled;
            let judge = await customWagers.getJudge(web3.sha3("wager1"));
            judge.should.equal(accounts[1]);

            await customWagersController.addJudge(web3.sha3("wager2"), accounts[1], { from: accounts[6] }).should.be.fulfilled;

        });

        it("should let anyone take wager", async function () {
            await customWagersController.takeWager(web3.sha3("wager1"), accounts[1], { from: accounts[2], value: wagerAmount }).should.be.fulfilled;
            await customWagersController.takeWager(web3.sha3("wager2"), accounts[1], { from: accounts[7], value: wagerAmount }).should.be.fulfilled;
        });



        // Dispute with Judge settlement
        it("should let the maker submit vote", async function () {
            await increaseTimeTo(latestTime() + 15);

            await customWagersController.submitVote(web3.sha3("wager1"), 1).should.be.fulfilled;
        });


        it("should let the taker submit vote", async function () {
            await customWagersController.submitVote(web3.sha3("wager1"), 2, { from: accounts[2] }).should.be.fulfilled;
        });

        it("should let the judge submit vote and settle wager", async function () {
            await customWagersController.submitJudgeVote(web3.sha3("wager1"), 2, { from: accounts[1] }).should.be.fulfilled;
            let winner = await customWagers.getWinner(web3.sha3("wager1"));
            winner.should.equal(accounts[2]);
        });


        // Dispute with Judge vote in between player votes
        it("should let the maker submit vote", async function () {
            await increaseTimeTo(latestTime() + 15);
            await customWagersController.submitVote(web3.sha3("wager2"), 1, { from: accounts[6] }).should.be.fulfilled;
        });

        it("should let the judge submit vote", async function () {
            await customWagersController.submitJudgeVote(web3.sha3("wager2"), 2, { from: accounts[1] }).should.be.fulfilled;
        });

        it("should not let the taker submit vote because bet is settled", async function () {
            await customWagersController.submitVote(web3.sha3("wager2"), 2, { from: accounts[7] }).should.be.rejectedWith(EVMRevert);
            let winner = await customWagers.getWinner(web3.sha3("wager2"));
            winner.should.equal(accounts[7]);
        });






    });


















    function wait(ms) {
        return new Promise((resolve) => setTimeout(() => resolve(), ms));
    }

    function eventOccurred(contract, eventName, timeout) {
        return new Promise((resolve, reject) => {
            let event = contract[eventName]({}, { fromBlock: 0, toBlock: 'latest' });
            event.watch((error, evt) => {
                event.stopWatching();
                resolve(evt);
            });
            setTimeout(() => reject(`Timed out waiting for event: ${eventName}`), timeout);
        });
    }

});
