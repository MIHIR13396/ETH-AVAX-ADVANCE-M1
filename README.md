# DeFi Kingdom Clone on Avalanche

## Description

This project aims to create a decentralized gaming experience, inspired by DeFi Kingdoms, on the Avalanche blockchain. Players can engage in activities such as exploring , purchasing , and battling using digital assets, earning rewards in custom tokens.
Player get an options of leaderboard based on token they have and can also transfer token to their friends in the game. They also get voting rights once they have won atleast one battle for major changes in game consider by owner.

## Getting Started

### Set Up Your EVM Subnet

## Step-by-Step Guide

### 1. Deploy your EVM Subnet using the Avalanche CLI

Follow the Avalanche documentation to create a custom EVM subnet on the Avalanche network. This subnet will serve as the environment where your smart contracts will be deployed.

### 2. Add your Subnet to Metamask

Ensure that your custom EVM subnet is added to Metamask so you can interact with it. Metamask will allow you to send transactions and interact with smart contracts deployed on your subnet.

### 3. Make sure it is your selected network in Metamask

Switch your Metamask network to your custom EVM subnet to ensure that all transactions and interactions occur on the correct network.

### 4. Connect Remix to your Metamask

Use the Remix IDE and connect it to Metamask using the Injected Provider. This connection allows Remix to interact with your Metamask account and deploy contracts directly from the Remix interface.

### Define Your Native Currency

Implement ```GameToken.sol``` contracts using  Remix. This token will serve as the in-game currency.

#### GameToken.sol

```solidity
// GameToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GameToken {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "XeronToken";
    string public symbol = "XRN";
    uint8 public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function transfer(address recipient, uint amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external returns (bool) {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
```

#### Vault.sol

```solidity
// Vault.sol
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
```
### 5. Deploy the smart contracts

Copy and paste your Solidity smart contract code into Remix. Compile the contracts and then deploy them to your custom EVM subnet using Remix's deployment interface.

### 6. Test your application!

## Gameplay Mechanics

### Token Management

Players can deposit their tokens into the vault to earn shares, representing ownership in the vault's total token balance. They can later withdraw tokens based on the shares they hold.

### Player Management

Each player is represented by a `Player` struct with attributes such as token balance, experience points, achievements, battle wins, explore count, voting rights, level, and name.

### Gameplay Actions

- **Register Player**: Players can register themselves with a name and initial attributes, initializing their gameplay state.
- **Battle**: Engage in battles with other players, where outcomes affect experience points and potentially grant voting rights.
- **Explore**: Players can explore, earning rewards such as tokens or experience points based on a random or predefined reward system.
- **Purchase Items**: Spend tokens on in-game items or upgrades to enhance gameplay.

### Leaderboard
- The contract maintains a leaderboard based on token balances and battle wins, updating dynamically as players interact with the system.

## Authors

MIHIR  
[@MIHIR SINGH](https://www.linkedin.com/in/mihir-singh-0974832a8)

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.






