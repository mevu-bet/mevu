const Mevu = artifacts.require("../build/Mevu.sol");
const Events = artifacts.require("../build/Events.sol");
const EventsController = artifacts.require("../build/EventsController.sol");
const Admin = artifacts.require("../build/Admin.sol");
const Wagers = artifacts.require("../build/Wagers.sol");
const WagersController = artifacts.require("../build/WagersController.sol");
const PoolWagersController = artifacts.require("../build/PoolWagersController.sol");
const CustomWagers = artifacts.require("../build/CustomWagers.sol");
const CustomWagersController = artifacts.require("../build/CustomWagersController.sol");
const CancelController = artifacts.require("../build/CancelController.sol");
const Rewards = artifacts.require("../build/Rewards.sol");
const Oracles = artifacts.require("../build/Oracles.sol");
const OraclesController = artifacts.require("../build/OraclesController.sol");
const OracleVerifier = artifacts.require("../build/OracleVerifier.sol");
const MvuToken = artifacts.require("../build/MvuToken.sol");
import { advanceBlock } from './helpers/advanceToBlock';
import ether from './helpers/ether';
import { increase } from './helpers/time';
import latest from './helpers/latestTime';
import EVMRevert from './helpers/EVMRevert';
const assertRevert = require('./helpers/assertRevert.js');
const BigNumber = require('bignumber.js');
const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();
const chai = require('chai');
chai.use(require('chai-bn')(BigNumber));

const wager1= web3.utils.sha3("wager1");
const wager2 = web3.utils.sha3("wager2");
const wager3 = web3.utils.sha3("wager3");
const wager4 = web3.utils.sha3("wager4");
const wager5 = web3.utils.sha3("wager5");
const gasAllowance = 1500000000000000;

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
    let poolWagersController;
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
    let latestTime;
    let teams = [web3.utils.sha3('team1'),
    web3.utils.sha3('team2'), web3.utils.sha3('team3'), web3.utils.sha3('team4')];
    let balanceA;
    let balanceB;
    let balanceC;
    let afterEventFinished = 1518839239;

    before(async function () {
        // Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
        await advanceBlock();
        //  web3 = new Web3(Web3.providers.WebsocketProvider('ws://localhost:8545'));
        latestTime = await latest();
        latestTime = Number(latestTime.toString());
    });

    beforeEach('setup contract for each test', async function () {
        mevu = await Mevu.deployed();
        events = await Events.deployed();
        eventsController = await EventsController.deployed();
        admin = await Admin.deployed();
        wagers = await Wagers.deployed();
        wagersController = await WagersController.deployed();
        poolWagersController = await PoolWagersController.deployed();
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

    });

    describe('testing Admin -- ', function () {
        it("it should let authorized change the oracle period", async function () {
            await admin.setOraclePeriod(1000).should.be.fulfilled;
        });
    });

    describe('verifying oracles -- ', function () {
        it("should let owner verify an oracle", async function () {
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

            await eventsController.makeEvent(web3.utils.sha3("test_event2"),
                latestTime,
                120,
                teams,
                false, { value: 10000 }).should.be.fulfilled;

            await eventsController.makeEvent(web3.utils.sha3("test_event3"),
                latestTime - 5,
                1,
                teams,
                false, { value: 10000 }).should.be.fulfilled;

            await eventsController.makeEvent(web3.utils.sha3("test_event4"),
                latestTime,
                120,
                teams,
                false, { value: 10000 }).should.be.fulfilled;

            await eventsController.makeEvent(web3.utils.sha3("test_event5"),
                latestTime,
                4000,
                teams,
                false, { value: 10000 }).should.be.fulfilled;
        });

        it("should add created event to activeEvents array", async function () {
            let included = false;
            for (let i = 0; i < await events.getActiveEventsLength(); i++) {

                console.log(await events.getActiveEventId(i));
                if (await events.getActiveEventId(i) == web3.utils.sha3("test_event2")) {
                    included = true;
                }
            }
            included.should.equal(true);
        });

        it("should let owner set min oracle num", async function () {
            await admin.setMinOracleNum(web3.utils.sha3("test_event2"), 3);
            await admin.setMinOracleNum(web3.utils.sha3("test_event3"), 3);
            await admin.setMinOracleNum(web3.utils.sha3("test_event4"), 2);
        });

    });



    describe('making wagers -- ', function () {

        it("it should let anyone make a pool wager", async function () {
            console.log("Minwager amount is " + web3.utils.fromWei(wagerAmount.toString()));
            let totalAmountBetPrior = await events.getTotalAmountBet(web3.utils.sha3("test_event2"));
            console.log("Total before " + totalAmountBetPrior);
            await poolWagersController.makeWager(wager1, web3.utils.sha3("test_event2"), wagerAmount.toString(), 0, { from: accounts[22], value: wagerAmount.toString(), gasPrice: 2000000000 }).should.be.fulfilled;

            await poolWagersController.makeWager(wager2, web3.utils.sha3("test_event2"), wagerAmount.toString(), 1, { from: accounts[23], value: wagerAmount.toString(), gasPrice: 2000000000 }).should.be.fulfilled;

            await poolWagersController.makeWager(wager3, web3.utils.sha3("test_event2"), wagerAmount.toString(), 2, { from: accounts[24], value: wagerAmount.toString(), gasPrice: 2000000000 }).should.be.fulfilled;

            let totalAmountBetPost = await events.getTotalAmountBet(web3.utils.sha3("test_event2"));
            console.log("Total after " + totalAmountBetPost);

            await poolWagersController.makeWager(wager4, web3.utils.sha3("test_event2"), wagerAmount.toString(), 1, { from: accounts[21], value: wagerAmount.toString(), gasPrice: 2000000000 }).should.be.fulfilled;

            await poolWagersController.makeWager(wager5, web3.utils.sha3("test_event4"), wagerAmount.toString(), 0, { from: accounts[2], value: wagerAmount.toString(), gasPrice: 2000000000 }).should.be.fulfilled;
        });

    });

    describe('updating events -- ', function () {
        it("should accept oracle votes and tokens for verified oracles for voteReady event", async function () {
            await increase(121);
            await oraclesController.registerOracle(web3.utils.sha3("test_event2"), 100000000, 1).should.be.fulfilled;
            await oraclesController.registerOracle(web3.utils.sha3("test_event2"), 100000000, 1, { from: accounts[1] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.utils.sha3("test_event2"), 200000000, 1, { from: accounts[2] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.utils.sha3("test_event2"), 10000000, 1, { from: accounts[3] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.utils.sha3("test_event2"), 1000000, 0, { from: accounts[4] }).should.be.fulfilled;
            await oraclesController.registerOracle(web3.utils.sha3("test_event2"), 10, 0).should.be.rejectedWith(EVMRevert);
           
        });

        
        it("should make a voteReady event locked after user finalizes", async function () {
            await increase(1025 + oraclePeriod);
            await eventsController.finalizeEvent(web3.utils.sha3("test_event4")).should.be.fulfilled;
            let locked = await events.getLocked(web3.utils.sha3("test_event4"));
            locked.should.equal(true);         

        });

        it("should have correct state", async function () {          
            let totalAmountBet = await events.getTotalAmountBet(web3.utils.sha3("test_event2"));
            totalAmountBet.toString().should.equal((wagerAmount * 4).toString());
        });


        it("should have a winner chosen now", async function () {          
            let winner = await events.getWinner(web3.utils.sha3("test_event2")).should.be.fulfilled;
            winner.toString().should.equal('1');
        });
    });

    describe('claiming wins -- ', function () {
        it("should allow the winner to recive winnings by calling claimWin", async function () {
            let origBal = await web3.eth.getBalance(accounts[21]).valueOf();
            await poolWagersController.claimWin(wager4, {from: accounts[21]}).should.be.fulfilled;
            let newBal =  await web3.eth.getBalance(accounts[21]).valueOf();
            let diff = newBal - origBal;
            let expectedValue = (wagerAmount * 2) * 0.97;
            diff.should.be.within(expectedValue - gasAllowance, expectedValue);
        });
    });

    describe('claiming refunds -- ', function () {
        it("should allow a refund to be claimed if no other teams are bet upon", async function () {
            let origBal = await web3.eth.getBalance(accounts[2]).valueOf();
            await poolWagersController.claimRefund(wager5, {from: accounts[2]}).should.be.fulfilled;
            let newBal =  await web3.eth.getBalance(accounts[2]).valueOf();
            let diff = newBal - origBal;
            let expectedValue = wagerAmount;
            diff.should.be.within(expectedValue - gasAllowance, expectedValue);
        });
    });

    

});