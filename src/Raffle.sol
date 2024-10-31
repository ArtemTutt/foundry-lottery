// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFConsumerBaseV2Plus} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author Artem Karelov
 * @notice This contract was created for fun and education
 * @dev Implements Chainlink VRFv2.5, foundry and etc.
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error Raffle_NotEnoughEth();
    error PickWinner_UpKeepNotNeeded();
    error Ruffle_TransferFailed();
    error Raffle_RaffleWasEnded();

    enum RuffleState {
        OPEN,
        CALCULATING,
        CLOSED
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3; // количество подтверждений

    uint32 private immutable i_callbackGasLimit; // The limit for how much gas to use for the callback request to your
    uint32 private constant NUM_WORDS = 1; // количество возвращаемых слов

    uint256 private immutable i_entranceFee; // начальная ставка для принятия участия в лотереи
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval; // интервал проведения лотереи
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_subscriptionId; // Идентификатор подписки, который этот контракт использует для запросов на финансирование.
    // address public owner; // владелец лотерее
    address payable[] private s_players; // массив всех участников
    address private s_recentWinner;
    bytes32 private immutable i_keyHash; // максимальное количество газа которое мы можем потратить
    RuffleState private s_ruffleState;

    /**
     * Events
     */
    event RuffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLine,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLine;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_ruffleState = RuffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETh to enter raffle");
        // if (msg.value < i_entranceFee) {
        //     revert NotEnoughEth();
        // }

        if (s_ruffleState != RuffleState.OPEN) {
            revert Raffle_RaffleWasEnded();
        }

        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEth();
        }

        s_players.push(payable(msg.sender));

        emit RuffleEntered(msg.sender);
    }

    /**
     * @dev Спец функция с chainlink которая проверяет, не истикло ли время лотереи, если истекло
     * то следует выбрать победителя(это значит автоматически будет вызвана функция определения победителя pickWinner)
     * @param - ignored
     * @return upKeepNeeded - true if нужно перезапустить лотерею и найти победителя для первого розыгрыша
     * @return - ignored
     */
    function checkUpKeep(bytes memory /*checkData */ )
        public
        view
        returns (bool upKeepNeeded, bytes memory /* performData */ )
    {
        // bool timeHasPased = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_ruffleState == RuffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upKeepNeeded = isOpen && hasBalance && hasPlayers;
        return (upKeepNeeded, hex"");
    }

    function pickWinner(bytes calldata /* performData */ ) external {
        // check to see if enough time has passed
        (bool upkeepNeeded,) = checkUpKeep("");

        if (!upkeepNeeded) {
            revert PickWinner_UpKeepNotNeeded(); // можно добавить параметры
        }

        s_ruffleState = RuffleState.CALCULATING;

        // Get our random number (отправляем запрос)
        // определяем рандомное число потом передаем его в функции fulfillRandomWords
        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    // обрабатываем запрос
    // определяем победителя
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner]; // winner of ruffle
        s_recentWinner = recentWinner;

        s_players = new address payable[](0); // обнуляем после нахождения победителя
        s_lastTimeStamp = block.timestamp;

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        // require(success, "failed send eth to winner");
        if (!success) {
            revert Ruffle_TransferFailed();
        }

        emit WinnerPicked(s_recentWinner);
    }

    /**
     * Getter Functtions
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() external view returns (RuffleState) {
        return s_ruffleState;
    }

    function getPlayer(uint indexOfPlayer) external view returns(address){
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns(uint) {
        return s_lastTimeStamp;
    }
}
