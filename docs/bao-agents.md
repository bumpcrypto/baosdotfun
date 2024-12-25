# BAO Agents

## Agent Overview

BAO agents are autonomous entities that manage specific aspects of fund operations. Our agents are NOT our product. They are simply a tool inside of the product. Each BAO(aside from the agent ran ones) employs 3-4 agents, with each agent specializing in distinct strategies. Using the bera/acc framework(a Berachain top down Eliza framework), agents can seamlessly interact with any Berachain protocol through a plugin architecture as well as the core Proof of Liquidity features.

## Agent Specializations

Agents focus on specific operational domains:

**Yield Farming Agent**

- Manages liquidity positions across protocols
- Vault deposits, Money Market supplying
- Rebalances portfolios for maximum efficiency

**Trading Agent**

- Executes spot trades on memecoins and Bera tokens
- Executes perp positions
- Analyzes market sentiment and momentum
- Manages entry and exit positions

**Strategy Agent**

- Identifies new protocol opportunities
- Analyzes cross-protocol yield strategies
- Evaluates new farming opportunities
- Monitors protocol health and risk metrics

**Mindshare/Personality agent(optional not needed for every BAO)** 

- Agent with a distinct personality for the fund on twitter ie an aixbt

## Security Infrastructure

### Trusted Execution Environment (TEE)

<aside>
💡

Our goal is to find a way for it to always be verifiable that our agents run on their own. But we’re still exploring the use of TEEs in prod. 

</aside>

- Agents operate within TEEs for verifiable autonomy
- Provides cryptographic proof of unaltered operation
- Ensures transparent decision-making processes
- Verifies absence of human intervention

### Smart Contract Backstops

- Position size limits(ie an agent cant use more than 5% of its portfolio to buy memecoins)
- Whitelisted protocol interactions
- Emergency shutdown mechanisms through Smart Contract wallets
- Multi-signature requirements for non-standard operations

## Incentive Distribution

Agents can control a portion of the distribution of incentive tokens into PoL Vaults to reward user contributions:

### Reward Criteria

- Strategy suggestions that generate returns
- Market intelligence that leads to profitable trades
- Protocol research that identifies opportunities

## Agent Communication

- Agent memos to their BAO on a weekly basis for farming
- Community can rotate out different agents of that season depending on preferences
- Chat list where people can give feedback to the agent in exchange for earning incentive tokens to stake into the [baos.fun](http://baos.fun) reward vault