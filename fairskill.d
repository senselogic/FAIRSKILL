/*
    This file is part of the FairSkill distribution.

    https://github.com/senselogic/FAIRSKILL

    Copyright (C) 2018 Eric Pelzer (ecstatic.coder@gmail.com)

    FairSkill is free software: you can redistribute it and/or modify
    it under the terms of the Creative Commons Attribution-ShareAlike
    International Public License, version 4.

    FairSkill is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    license file for more details.
*/

// -- IMPORTS

import std.algorithm : max, min;
import std.conv : to;
import std.math : abs;
import std.random : uniform;
import std.stdio : write, writeln;

// -- CONSTANTS

enum SkillCount = 20000;
enum TierCount = 8;
enum TierDivisionCount = 4;
enum TierSkillCount = SkillCount / TierCount;
enum DivisionSkillCount = TierSkillCount / TierDivisionCount;
enum DivisionMinimumGameCount = 2;
enum GameMaximumPositiveSkillOffset = DivisionSkillCount / DivisionMinimumGameCount;
enum GameMaximumNegativeSkillOffset = GameMaximumPositiveSkillOffset;
enum PlacementGameCount = 10;
enum PlacementGameMaximumPositiveSkillOffset = TierSkillCount * 2;
enum PlacementGameMaximumNegativeSkillOffset = PlacementGameMaximumPositiveSkillOffset / 2;
enum DefaultSkill = 0;
enum MinimumPlayTime = 60;
enum TeamPlayerCount = 6;
enum GamePlayerCount = TeamPlayerCount * 2;
enum PlayerCount = 100;
enum GameCount = PlayerCount * 50;
enum PlayerTestCount = 5;

// -- TYPES

class PLAYER
{
    // -- ATTRIBUTES

    long
        Id;
    double
        Skill,
        TrueSkill;
    bool
        ItHasWon;
    int
        RemainingPlacementGameCount;
    long
        FinishedGameCount;

    // -- CONSTRUCTORS

    this(
        long id,
        double true_skill
        )
    {
        Id = id;
        Skill = DefaultSkill;
        TrueSkill = true_skill;
        ItHasWon = false;
        RemainingPlacementGameCount = PlacementGameCount;
        FinishedGameCount = 0;
    }

    // -- INQUIRIES

    long GetTierIndex(
        long player_index,
        long player_count
        )
    {
        return ( player_index * TierSkillCount ) / player_count;
    }

    // ~~

    long GetDivisionIndex(
        long player_index,
        long player_count
        )
    {
        return ( ( player_index * TierSkillCount * DivisionSkillCount ) / player_count ) % DivisionSkillCount;
    }

    // ~~

    void Dump(
        )
    {
        writeln(
            "[",
            Id,
            "] ",
            Skill,
            " (",
            TrueSkill,
            ") ",
            FinishedGameCount,
            " ",
            ItHasWon
            );
    }
}

// ~~

class PLAYER_SCORE
{
    // -- ATTRIBUTES

    PLAYER
        Player;
    int
        TeamIndex;
    double
        PlayTime,
        PointCount,
        NormalizedPointCount,
        SkillOffset;
    TEAM_SCORE
        TeamScore;
    GAME_SCORE
        GameScore;

    // -- CONSTRUCTORS

    this(
        int team_index
        )
    {
        TeamIndex = team_index;
        PlayTime = 300.0;
    }

    // -- INQUIRIES

    void Dump(
        )
    {
        writeln(
            "    [" ,
            Player.Id,
            "] ",
            Player.ItHasWon,
            " ",
            TeamIndex,
            " ",
            PlayTime,
            " ",
            NormalizedPointCount,
            " => ",
            SkillOffset,
            " => ",
            Player.Skill,
            "/",
            Player.TrueSkill
            );
    }

    // -- OPERATIONS

    void UpdateSkillOffset(
        )
    {
        double
            game_maximum_negative_skill_offset,
            game_maximum_positive_skill_offset,
            skill_offset;
        TEAM_SCORE
            other_team_score;

        if ( Player.RemainingPlacementGameCount > 0 )
        {
            --Player.RemainingPlacementGameCount;

            game_maximum_positive_skill_offset = PlacementGameMaximumPositiveSkillOffset;
            game_maximum_negative_skill_offset = PlacementGameMaximumNegativeSkillOffset;
        }
        else
        {
            game_maximum_positive_skill_offset = GameMaximumPositiveSkillOffset;
            game_maximum_negative_skill_offset = GameMaximumNegativeSkillOffset;
        }

        SkillOffset = 0;

        if ( PlayTime >= MinimumPlayTime )
        {
            Player.ItHasWon = TeamScore.ItHasWon;
            other_team_score = GameScore.TeamScoreArray[ 1 - TeamIndex ];

            if ( Player.Skill < SkillCount - game_maximum_positive_skill_offset )
            {
                if ( TeamScore.ItHasWon
                     && NormalizedPointCount >= TeamScore.AverageNormalizedPointCount )
                {
                    SkillOffset
                        = game_maximum_positive_skill_offset
                          * ( NormalizedPointCount + 1 )
                          / ( NormalizedPointCount + TeamScore.AverageNormalizedPointCount + 1 );
                }
                else if ( !TeamScore.ItHasWon
                     && NormalizedPointCount <= TeamScore.AverageNormalizedPointCount )
                {
                    SkillOffset
                        = -game_maximum_negative_skill_offset
                          * ( TeamScore.AverageNormalizedPointCount + 1 )
                          / ( TeamScore.AverageNormalizedPointCount + NormalizedPointCount + 1 );
                }
            }

            foreach ( ref other_player_score; GameScore.PlayerScoreArray )
            {
                if ( other_player_score.PlayTime > MinimumPlayTime )
                {
                    skill_offset = 0;

                    if ( TeamScore.ItHasWon
                         && NormalizedPointCount >= other_player_score.NormalizedPointCount
                         && Player.Skill <= other_player_score.Player.Skill )
                    {
                        skill_offset
                            = ( other_player_score.Player.Skill - Player.Skill )
                              * ( NormalizedPointCount + 1 )
                              / ( NormalizedPointCount + other_player_score.NormalizedPointCount + 1 );
                    }
                    else if ( !TeamScore.ItHasWon
                              && NormalizedPointCount <= other_player_score.NormalizedPointCount
                              && Player.Skill >= other_player_score.Player.Skill )
                    {
                        skill_offset
                            = ( other_player_score.Player.Skill - Player.Skill )
                              * ( other_player_score.NormalizedPointCount + 1 )
                              / ( other_player_score.NormalizedPointCount + NormalizedPointCount + 1 );
                    }

                    SkillOffset += skill_offset / TeamPlayerCount;
                }
            }
        }
    }

    // ~~

    void UpdateSkill(
        )
    {
        Player.Skill += SkillOffset;

        if ( Player.Skill < 0 )
        {
            Player.Skill = 0;
        }

        if ( Player.Skill >= SkillCount )
        {
            Player.Skill = SkillCount;
        }

        if ( PlayTime >= MinimumPlayTime )
        {
            ++Player.FinishedGameCount;
        }
    }
}

// ~~

class TEAM_SCORE
{
    // -- ATTRIBUTES

    int
        TeamIndex;
    PLAYER_SCORE[]
        PlayerScoreArray;
    double
        PointCount,
        NormalizedPointCount,
        NormalizedPlayerCount,
        AverageNormalizedPointCount,
        AverageSkill,
        MinimumSkill,
        MaximumSkill,
        SkillCount;
    bool
        ItHasWon;

    // -- CONSTRUCTORS

    this(
        int team_index
        )
    {
        TeamIndex = team_index;
        ItHasWon = false;
    }

    // -- INQUIRIES

    void Dump(
        )
    {
        writeln( "Team " , TeamIndex, " : ", PointCount );

        foreach( ref player_score; PlayerScoreArray )
        {
            player_score.Dump();
        }
    }
}

// ~~

class GAME_SCORE
{
    // -- ATTRIBUTES

    PLAYER_SCORE[]
        PlayerScoreArray;
    TEAM_SCORE[]
        TeamScoreArray;
    double
        PlayTime,
        PointCount,
        NormalizedPointCount;

    // -- CONSTRUCTORS

    this(
        )
    {
        TeamScoreArray = new TEAM_SCORE[ 2 ];
        PlayTime = 5 * 60;
    }

    // -- INQUIRIES

    void Dump(
        )
    {
        foreach ( ref team_score; TeamScoreArray )
        {
            team_score.Dump();
        }
    }

    // -- OPERATIONS

    void UpdateSkill(
        )
    {
        NormalizedPointCount = 0;

        foreach ( ref team_score; TeamScoreArray )
        {
            team_score.PointCount = 0;
            team_score.NormalizedPointCount = 0;
            team_score.NormalizedPlayerCount = 0;
            team_score.AverageNormalizedPointCount = 0;
            team_score.AverageSkill = 0;
            team_score.MaximumSkill = 0;
        }

        foreach ( ref team_score; TeamScoreArray )
        {
            foreach ( ref player_score; team_score.PlayerScoreArray )
            {
                team_score.PointCount += player_score.PointCount;

                if ( player_score.PlayTime > MinimumPlayTime )
                {
                    player_score.NormalizedPointCount = ( player_score.PointCount * PlayTime ) / player_score.PlayTime;
                    ++team_score.NormalizedPlayerCount;
                    team_score.AverageNormalizedPointCount += player_score.NormalizedPointCount;
                }
                else
                {
                    NormalizedPointCount = 0;
                }

                NormalizedPointCount += player_score.NormalizedPointCount;
                team_score.NormalizedPointCount += player_score.NormalizedPointCount;
                team_score.AverageSkill += player_score.Player.Skill;

                if ( player_score.Player.Skill > team_score.MaximumSkill )
                {
                    team_score.MaximumSkill = player_score.Player.Skill ;
                }
            }

            if ( team_score.NormalizedPlayerCount > 0 )
            {
                team_score.AverageNormalizedPointCount /= team_score.NormalizedPlayerCount;
            }

            team_score.AverageSkill /= team_score.PlayerScoreArray.length;
        }

        foreach ( ref team_score; TeamScoreArray )
        {
            team_score.ItHasWon = ( team_score.PointCount > TeamScoreArray[ 1 - team_score.TeamIndex ].PointCount );
        }

        foreach ( ref player_score; PlayerScoreArray )
        {
            player_score.UpdateSkillOffset();
        }

        foreach ( ref player_score; PlayerScoreArray )
        {
            player_score.UpdateSkill();
        }
    }

    // ~~

    bool HasPlayer(
        ref PLAYER player
        )
    {
        foreach ( ref player_score; PlayerScoreArray )
        {
            if ( player_score.Player is player )
            {
                return true;
            }
        }

        return false;
    }
}

// ~~

class PLAYER_TABLE
{
    // -- ATTRIBUTES

    PLAYER[]
        PlayerArray;

    // -- CONSTRUCTORS

    this(
        )
    {
        PlayerArray = new PLAYER[ PlayerCount ];

        foreach ( player_index; 0 .. PlayerCount )
        {
            PlayerArray[ player_index ] = new PLAYER( player_index, ( player_index + 1 ) * SkillCount / PlayerCount );
        }
    }

    // -- INQUIRIES

    void Dump(
        )
    {
        foreach ( player; PlayerArray )
        {
            player.Dump();
        }
    }

    // -- OPERATIONS

    GAME_SCORE MakeGameScore(
        )
    {
        double
            skill_offset_factor;
        int
            player_index,
            player_test_count;
        GAME_SCORE
            game_score;
        PLAYER
            player;
        PLAYER_SCORE
            player_score;
        TEAM_SCORE
            team_score;

        game_score = new GAME_SCORE();

        foreach ( team_index; 0 .. 2 )
        {
            team_score = new TEAM_SCORE( team_index );

            game_score.TeamScoreArray[ team_index ] = team_score;
        }

        foreach ( team_index; 0 .. 2 )
        {
            team_score = game_score.TeamScoreArray[ team_index ];

            foreach ( team_player_index; 0 .. TeamPlayerCount )
            {
                player_score = new PLAYER_SCORE( team_index );

                skill_offset_factor = 1.0;
                player_test_count = PlayerTestCount;

                do
                {
                    player_index = uniform( 0, PlayerCount );
                    player = PlayerArray[ player_index ];
                    player_score.Player = player;
                    player_score.PointCount = player.TrueSkill;

                    if ( player_test_count > 0 )
                    {
                        --player_test_count;
                    }
                    else
                    {
                        skill_offset_factor += 0.01;
                        player_test_count = PlayerTestCount;
                    }
                }
                while (
                    game_score.HasPlayer( player_score.Player )
                    || ( game_score.PlayerScoreArray.length > 0
                         && ( abs( game_score.PlayerScoreArray[ 0 ].Player.Skill - player.Skill ) > ( skill_offset_factor * TierSkillCount ).to!int() ) )
                    );

                player_score.TeamScore = team_score;
                player_score.GameScore = game_score;

                team_score.PlayerScoreArray ~= player_score;
                game_score.PlayerScoreArray ~= player_score;
            }
        }

        return game_score;
    }

    // ~~

    void UpdateSkill(
        )
    {
        GAME_SCORE
            game_score;

        game_score = MakeGameScore();
        game_score.UpdateSkill();
    }
}

// -- FUNCTIONS

void main(
    )
{
    PLAYER_TABLE
        player_table;

    player_table = new PLAYER_TABLE;

    foreach ( game_index; 0 .. GameCount )
    {
        player_table.UpdateSkill();

        if ( game_index == PlayerCount * PlacementGameCount / TeamPlayerCount
             || game_index == 2 * PlayerCount * PlacementGameCount / TeamPlayerCount
             || game_index == GameCount - 1 )
        {
            writeln( "-- GAME ", game_index, " --" );

            player_table.Dump();
        }
    }
}
