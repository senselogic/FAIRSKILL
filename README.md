![](https://github.com/senselogic/FAIRSKILL/blob/master/LOGO/fairskill.png)

# FairSkill

Skill-based ranking algorithm.

## Description

FairSkill sorts a list of players by increasing matchmaking skill, estimated from their performance during a series of games.

The player skill is adjusted only when he plays better/worse than his opponents and teammates with a higher/lower skill.

## Algorithm

When a player finishes a game, his skill is adjusted only if he has played for a minimum duration.

The score of a player who has joined an ongoing game is first normalized by dividing it by his play time during the last game.

The lost/won skill points of a player are proportional to the average normalized skill difference at the end of the game.

If a player wins/looses with a higher/lower normalized score than the average normalized score of his team,
his skill increases/decreases by a fraction of a ranking division, proportionally to the normalized average score difference.

If a player wins/looses with a higher/lower normalized score than a higher/lower skill player,
his skill increases/decreases toward that skill, proportionally to the normalized score difference.

Only players who have started a game can loose some skill.

## Compilation

To compile the reference implementation of the algorithm, first install the [DMD 2 compiler](https://dlang.org/download.html).

Then build the executable with the following command line :

```bash
dmd -m64 fairskill.d
```

## Version

1.0

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the Creative Commons Attribution-ShareAlike 4.0 International Public License.

See the [LICENSE.md](LICENSE.md) file for details.
