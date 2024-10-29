// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {console} from "../../lib/forge-std/src/console.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLine;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant PLAYER_BALANCE_ETHER = 10 ether;

    event RuffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.deal(PLAYER, PLAYER_BALANCE_ETHER);

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLine = config.gasLine;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }

    function testRaffleInitializesInopenState() public view {
        assert(raffle.getRaffleState() == Raffle.RuffleState.OPEN);
    }

    function testRaffleRevertWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Asset
        vm.expectRevert(Raffle.Raffle_NotEnoughEth.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
         // Arrange
        vm.prank(PLAYER);
        // Act / Asset
        raffle.enterRaffle{value: entranceFee}();

        address playerRecorded = raffle.getPlayer(0);

        assert(playerRecorded == PLAYER);
        console.log("This is playerRecorded", playerRecorded);
        console.log("This is PLAYER", PLAYER);
    }

    function testRaffleEventWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Asset
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RuffleEntered(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleCalculating() public {
         // Arrange
        vm.prank(PLAYER);
        // Act / Asset
        raffle.enterRaffle{value: entranceFee}();

        // vm.wrap - sets block.timestamp - ипользуем для автоматического изминения времени как нам нужно 
        // vm.block - sets block.number - изменяет номер блока

    }

    function testcheckUpKeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.prank(PLAYER); // мы не передали денежные средства 
        // Act / Asset
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeeper, ) = raffle.checkUpKeep("");

        assert(!upkeeper);
    }

    function testCheckUpKeepReturnsTrueWhenParametrsAreGood() public {
        // Arrange
        vm.prank(PLAYER); // мы не передали денежные средства

        raffle.enterRaffle{value: entranceFee}();

        // we did enterRaffle => s_players have people, contract has balance
        assert(raffle.getRaffleState() == Raffle.RuffleState.OPEN);
        (bool upkeeper, ) = raffle.checkUpKeep("");

        assert(upkeeper);
    }

    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        // Arrange
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = raffle.checkUpKeep("");
        // Act

        raffle.pickWinner("");

        console.log(raffle.getRaffleState() == Raffle.RuffleState.CALCULATING);
    }


    function testPerformUpKeepRevertIfCheckUpKeepIsTrue() public {
        // Arrange
        vm.startPrank(PLAYER); // мы не передали денежные средства
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = raffle.checkUpKeep("");
        // Act

        vm.expectRevert(Raffle.PickWinner_UpKeepNotNeeded.selector);

        raffle.pickWinner("");
    }

    /*//////////////////////////////////////////////////////////////
                           Check Getter Function
    //////////////////////////////////////////////////////////////*/

    function testCheckGetEntranceFee() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Asset

        raffle.enterRaffle{value: entranceFee}();

        console.log(entranceFee);
        console.log(raffle.getEntranceFee());

        assert(raffle.getEntranceFee() == 1e16);
    }

    function testCheckGetRecentWinner () public {
        // didn implemented pickWinner yet => RecentWinner == address(0)
        // Arrange
        vm.prank(PLAYER);
        // Act / Asset

        raffle.enterRaffle{value: entranceFee}();

        address recWinner = raffle.getRecentWinner();

        console.log(recWinner);

        assert(recWinner == address(0));
    }

    function testCheckGetRaffleState () public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Asset

        raffle.enterRaffle{value: entranceFee}();

        assert(raffle.getRaffleState() == Raffle.RuffleState.OPEN);
    }

    function testCheckGetPlayer() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Asset

        raffle.enterRaffle{value: entranceFee}();

        assert(raffle.getPlayer(0) == PLAYER);
    }


    /*//////////////////////////////////////////////////////////////
                           FULFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    function testFulFillRandomWordsOnlyBeColdAfterPickWinner() public {
        
    }
}