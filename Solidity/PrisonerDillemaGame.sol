// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PrisonerDilemmaCoin.sol"; // Ensure this path is correct

contract PrisonersDilemmaGame {
    struct Player {
        uint256 deposit;         // Amount of tokens deposited by the player
        bytes32 commitment;      // Commitment (hash of choice and nonce)
        bool hasChosen;          // Flag indicating if the player has made a choice
        bool hasRevealed;        // Flag indicating if the player has revealed their choice
        bool choice;  
        uint256 roundJoined;            // The actual choice made by the player (true for betray, false for cooperate)
    }

    PrisonerDilemmaCoin public pdcToken;       // Instance of the PrisonerDilemmaCoin contract
    uint256 public entryFee;                    // Entry fee in PDC tokens
    uint256 public roundDuration;               // Round duration in seconds (2 weeks)
    uint256 public roundEndTime;                // End time for the current round
    address public owner;                        // Owner of the game
    uint256 public currentRound;                // Track the current round number
    mapping(address => Player) public players;   // Mapping to track player information
    address[] public participants;                // List of participants

    event PlayerJoined(address indexed player, uint256 amount);
    event ChoiceMade(address indexed player, bool choice);
    event Payout(address indexed player, uint256 reward);
    event RoundFinalized(uint256 round);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(PrisonerDilemmaCoin _pdcToken, uint256 _entryFee, uint256 _roundDuration) {
        require(_entryFee > 0, "Entry fee must be greater than zero");
        require(_roundDuration > 0, "Round duration must be greater than zero");
        pdcToken = _pdcToken;
        entryFee = _entryFee;
        roundDuration = _roundDuration;
        owner = msg.sender;
        currentRound = 1;
        roundEndTime = block.timestamp + roundDuration;
    }

    // Players join the game
    function joinGame() external {
        require(pdcToken.transferFrom(msg.sender, address(this), entryFee), "Transfer failed");
        require(players[msg.sender].roundJoined < currentRound, "Already joined this round");

        participants.push(msg.sender);
        players[msg.sender] = Player({
            deposit: entryFee,
            commitment: bytes32(0),
            hasChosen: false,
            hasRevealed: false,
            choice: false,
            roundJoined: currentRound
        });

        emit PlayerJoined(msg.sender, entryFee);
    }

    // Players commit their choice
    function commitChoice(bool _betray, uint256 _nonce) external {
        require(players[msg.sender].deposit > 0, "Not a participant");
        require(!players[msg.sender].hasChosen, "Choice already made");

        // Store the commitment (hash of choice and nonce)
        players[msg.sender].commitment = keccak256(abi.encodePacked(_betray, _nonce));
        players[msg.sender].hasChosen = true;

        // Assume they chose to betray or cooperate based on the _betray parameter
        players[msg.sender].choice = _betray;

        emit ChoiceMade(msg.sender, _betray);
    }

    // Finalize the round and calculate payouts
    function finalizeRound() external {
        require(block.timestamp >= roundEndTime, "Current round still ongoing");
        require(currentRound > 0, "No round to finalize");

        uint256 betrayers = 0;
        uint256 totalDeposits = 0;

        // Count betrayers and sum deposits
        for (uint256 i = 0; i < participants.length; i++) {
            Player storage player = players[participants[i]];
            if (player.hasChosen) {
                totalDeposits += player.deposit;

                // Determine if the player betrayed or cooperated
                if (player.choice) { // True indicates betrayal
                    betrayers++;
                }
            }
        }

        // Distribute rewards based on the game's outcome
        for (uint256 i = 0; i < participants.length; i++) {
            Player storage player = players[participants[i]];
            uint256 payout;

            if (betrayers == participants.length) {
        // Case 1: Everyone betrayed
        // Each player loses 90% of their deposit
        payout = player.deposit / 10;

            } else if (betrayers == 0) {
                // Case 2: Everyone cooperated
                // Everyone gets 100% of their deposit back
                payout = player.deposit;

            } else if (player.choice) { 
                // Case 3: This player betrayed
                // Betrayers earn 30% profit on their deposit (130%)
                payout = player.deposit * 130 / 100;

            } else {
                // Case 4: This player cooperated but some betrayed
                // Cooperators lose 50% of their deposit
                payout = player.deposit / 2;
            }

            // Transfer the payout in PDC tokens
            pdcToken.transfer(participants[i], payout);
            emit Payout(participants[i], payout);

            // Reset player's state for the next round
            player.hasChosen = false;
            player.commitment = bytes32(0); // Clear the commitment properly
            player.choice = false; // Reset choice
            player.hasRevealed = false; // Reset reveal status
        }

        // Prepare for the next round
        currentRound++;
        roundEndTime = block.timestamp + roundDuration; // Set the end time for the next round
        emit RoundFinalized(currentRound - 1);
    }
}
