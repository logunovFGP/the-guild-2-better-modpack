
## Reforged-AI ##

### 2025-04-18 ###

- [Basetree/Idle] On nearly every political meeting minimum the half of the politicians stay away from the meeting what makes ranking up in the politics very hard because maybe the people you are good with dont come and vote for you

- [Behavior] The family does not react on fire outside of the city 

- [Basetree] At the late game dynasties actively dying out. There are no active actions against them, just no childs

- [] I noticed that (Hanseatic map, 12 dynasties) nobody builds new buildings in Bergen aside me, even though there are tons of free space. Around 20-30 years into the game,. Maybe that is how it's intended in game and vanilla they dont build either, I dont know. The town starts with tavern, church, forge, the random families owning it even upgrade it to tier 2, but nobody builds new tier 1 buildings to start producing basic resources for these buildings. So those buildings dont produce anything either. This means that until I would build out an entire patron+craft+scholar resources chain single handedly many decades in for this town, almost all goods in their market, even many basic ones like barley or wood, will be at 0 forever.

- [Idle-Thug] In same town, Bergen, tiny town w 3 office positions and no resource chain, year 20, there are 30+ thugs running around, all of them belong to minor/neutral dynasties (no color or coat of arms). I only have 2 thugs myself. At all times, there are ~10 no-color thugs following my dynasty head, spying, they swarm around every building he's in. It's hilarious but probably shouldn't be like this.

- [Basetree] AI tends to remain friends forever, there should be more causes for them to dislike players or at least make sure that each player always has at least one enemy (compare Fugger 2: If current archenemy died or got too weak, he was replaced by another.) 

- [Basetree] Workshop expansion not working properly?

- [Basetree] No AI actions on impending war, send char or buy soldiers.

- [Basetree] No banquets

- [Basetree] Rare poison well of alchemists (?)



## Reforged-TWP ##

Base idea: Branch out the reforged project to include the best TWP features. 

### Feature selection ###

- Send card, load and return
- Improved idle behaviour for thugs and dyn members
- AI Basetree
- Attractivity calculation (groundwork in reforged base)
- Sales counter
- Balance sheets for all workshops
- increased likelihood of city events: fire, plague


## TODO 2020-11-20 ##

- replace calls to escort functions to add escorts by script
- DONE state_autocart should supply by priorities: own workshops, market, other workshops



## Projects ##

### Burglary Rework ###

Problems with vanilla implementation: 

- thieves die too quickly
- effect of scouting is unclear and illogical (increased loot)
- sending several thieves starts action several times (evidence)


Ideas for rework: 

- reduce detection range
- use squad logic: first thief tries to get in, second is lookout and any additional thieves try to get in
- loot increases with additional squad members
- scouting reduces time needed
- burglary can fail via skill check of thieves dexterity vs. building protection



### Lightweight lua classes ###

Policies: 

- naming scheme for global variables (i.e. CAPS, #Var)
- only use global variables if necessary, prefer hiding functions or grouping, i.e.
	- Diseases.Cold.infectSim("SIM") instead of Cold.infectSim("SIM") 


Usage: 

- Diseases.Cold.infectSim("SIM")
- Diseases.Cold.cureSim("SIM")



### Coordinated Production Measures ###

#### Data model ####

Building = {
	WorkerTask0..5 : PROD | GATHER | HEAL | PICKPOCKET | ...
	WorkerDetail0..5 : Crowded-Index | ItemID | 
	WorkerAssigned0..5 : SimID
}

Worker = {
	WorkerTaskIdx : 0..5
}


#### Process ####

1. Building.Setup calculates required tasks for maximum worker count of level and writes properties.

2. Idle worker checks current worker tasks from 0..5 and chooses first task that is either unassigned or assigned to himself

3. Idle worker reads the task detail, i.e. to find a destination

4. Building.OnLevelUp and Building.PingHour update workertasks as necessary. 



## AI ##

### By Theme ###


**Expansion** in building scripts:

- _Expansion increases the economy and needs to be done whenever possible._

- Check for building upgrades once a day (PingHour, see bld_ForceLevelUp)

- Check for new buildings to buy or build in residence (PingHour)


**Courting and Relationships** in character idle scripts (only colored dynasties, not shadow):

- _Only you know the desires of your own heart._

- Initiate the courting once old enough

- Courting actions, depending on cooldowns

- Marriage when available

- Intercourse at night times


**Production:**

- _The workshops master decides, the worker only does his duty._

- Buildings compute all values needed for production and production measures

- Workers check building properties for special production measures (healing, hoaxing, gathering)

- Carts check building properties for required goods



### By Entity ###

#### Dynasty SIM ####

Personal decisions of dynasty SIMs are handled in the corresponding idle script (std_idle or ms_DynastyIdle) and 
mostly concern surival, family, work and social life: 

- Medical treatment
- Courting and relationships, including intercourse
- Special education for children (artefacts)
- Work (going to workshops, includes bonus payments and propel workers)
- Leisure actions (includes tavern, sitting around, maybe walks outside of town)
- Sleeping
- Use artefacts with personal bonuses


Inactive dynasty SIMs should get a reduced set of actions: 

- Medical treatment
- Leisure actions (includes tavern, sitting around, maybe walks outside of town)
- Sleeping
- Use artefacts with personal bonuses


#### Dynasty BaseTree ####

Dynasty actions are coordinated in the AI BaseTree. If the BaseTree is kept lean then the AI will be able to react 
quickly to current events. This could greatly improve the 'felt' strength of the AI. I.e. the AI could try to counter 
an attack or a sabotage on its buildings by sending any available fighters to the scene.  

- Reactions to current events (attacks, sabotage)
- Actions against other dynasties
- Defensive measures depending on current dynasty relations
- Preparations for events (trials, elections, war)
- Privileges


#### Building ####

Building AI is placed in the PingHour of buildings. Calculations need to be minimal or else they will cause hourly lags.  

- Upgrades
- Repairs
- Production


#### Non-Dynasty SIM ####

Most rogue workers require AI logic in the idle scripts to enable worker AI for players.
Aside from this the general population will go about normal activities.  

- Production measures based on building settings
- Shopping
- Leisure time


