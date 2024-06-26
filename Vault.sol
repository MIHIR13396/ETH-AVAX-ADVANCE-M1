// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./GameToken.sol";

contract Vault {
    GameToken public immutable token;

    struct Player {
        uint tokenBalance;
        uint experiencePoints;
        uint achievements;
        uint battleWins;
        uint exploreCount;
        bool votingRights;
        uint level;
        string name;
    }

    uint public totalSupply;
    mapping(address => Player) public players;
    address[] public playerAddresses;
    uint private playerCounter;

    constructor(address _token) {
        token = GameToken(_token);
    }

    function _mint(address _to, uint _shares) private {
        totalSupply += _shares;
        players[_to].tokenBalance += _shares;
    }

    function _burn(address _from, uint _shares) private {
        totalSupply -= _shares;
        players[_from].tokenBalance -= _shares;
    }

    function deposit(uint _amount) external {
        uint shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
        updateLeaderboard();
    }

    function withdraw(uint _shares) external {
        uint amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        token.transfer(msg.sender, amount);
        updateLeaderboard();
    }

    function registerPlayer(string memory _name, uint _level, uint _initialTokens) external {
        playerCounter++;
        address playerAddress = address(uint160(playerCounter));
        
        players[playerAddress] = Player(_initialTokens, 0, 0, 0, 0, false, _level, _name);
        playerAddresses.push(playerAddress);

        // Simulate initial battles and exploring for the player
        simulateBattles(playerAddress, 0); // Simulate 0 battle wins
        simulateExploring(playerAddress, 0); // Simulate exploring 0 times

        updateLeaderboard();
    }

    function battle(address _playerAddress) external {
        require(players[msg.sender].tokenBalance > 0, "Insufficient balance");
        require(players[_playerAddress].tokenBalance > 0, "Selected player has insufficient balance");

        bool victory = (block.timestamp % 1 == 0); // Simple random condition for victory
        if (victory) {
            players[_playerAddress].battleWins++;
            players[_playerAddress].experiencePoints += 10;
        }
        if (players[_playerAddress].experiencePoints >= 10) {
            players[_playerAddress].votingRights = true;
        }

        // Update leaderboard after the battle
        updateLeaderboard();
    }

    function explore() external {
        require(players[msg.sender].tokenBalance > 0, "Insufficient balance");
        uint reward = 50; // Random reward
        players[msg.sender].exploreCount++;
        players[msg.sender].tokenBalance += reward; // Update token balance directly
        updateLeaderboard();
    }

    function purchaseItem(uint _amount) external {
        require(players[msg.sender].tokenBalance >= _amount, "Insufficient balance");
        players[msg.sender].tokenBalance -= _amount; // Deduct tokens directly
        // Logic for purchasing items goes here
    }

    function transferTokens(address _recipient, uint _amount) external {
        require(players[msg.sender].tokenBalance >= _amount, "Insufficient balance");
        players[msg.sender].tokenBalance -= _amount;
        players[_recipient].tokenBalance += _amount;
    }

    function getLeaderboard() external view returns (address[] memory) {
        address[] memory sortedAddresses = new address[](playerAddresses.length);
        for (uint i = 0; i < playerAddresses.length; i++) {
            sortedAddresses[i] = playerAddresses[i];
        }

        // Sort leaderboard by token balance (descending), and if tied, by battle wins
        for (uint i = 0; i < sortedAddresses.length; i++) {
            for (uint j = i + 1; j < sortedAddresses.length; j++) {
                address playerA = sortedAddresses[i];
                address playerB = sortedAddresses[j];
                if (players[playerA].tokenBalance < players[playerB].tokenBalance ||
                    (players[playerA].tokenBalance == players[playerB].tokenBalance &&
                    players[playerA].battleWins < players[playerB].battleWins)) {
                    address temp = sortedAddresses[i];
                    sortedAddresses[i] = sortedAddresses[j];
                    sortedAddresses[j] = temp;
                }
            }
        }
        return sortedAddresses;
    }

    function getPlayer(address _player) external view returns (Player memory) {
        return players[_player];
    }

    function clearPlayerData(address playerAddress) private {
        delete players[playerAddress];
        // Remove player address from playerAddresses array
        for (uint i = 0; i < playerAddresses.length; i++) {
            if (playerAddresses[i] == playerAddress) {
                playerAddresses[i] = playerAddresses[playerAddresses.length - 1];
                playerAddresses.pop();
                break;
            }
        }
    }

    function simulateBattles(address playerAddress, uint count) private {
        for (uint i = 0; i < count; i++) {
            players[playerAddress].battleWins++;
            players[playerAddress].experiencePoints += 10;
        }
        updateLeaderboard();
    }

    function simulateExploring(address playerAddress, uint count) private {
        for (uint i = 0; i < count; i++) {
            players[playerAddress].exploreCount++;
            uint reward = 50; // Fixed reward
            players[playerAddress].tokenBalance += reward;
        }
        updateLeaderboard();
    }

    function updateLeaderboard() private {
        // Bubble sort to maintain the leaderboard order
        for (uint i = 0; i < playerAddresses.length; i++) {
            for (uint j = i + 1; j < playerAddresses.length; j++) {
                if (players[playerAddresses[i]].tokenBalance < players[playerAddresses[j]].tokenBalance ||
                    (players[playerAddresses[i]].tokenBalance == players[playerAddresses[j]].tokenBalance &&
                    players[playerAddresses[i]].battleWins < players[playerAddresses[j]].battleWins)) {
                    address temp = playerAddresses[i];
                    playerAddresses[i] = playerAddresses[j];
                    playerAddresses[j] = temp;
                }
            }
        }
    }
}
