#!/usr/local/bin/python
from ..exceptions import InvalidMoveException
from ..models.move import Move, MoveType
from ..models.game import Game
from ..models.piece import Piece
from .abstract_move_update_service import AbstractMoveUpdateService


class PlaceMoveUpdateService(AbstractMoveUpdateService):
    def __init__(self, setup_squares_for_color):
        self.__setup_squares_for_color = setup_squares_for_color

    def get_move_type(self):
        return MoveType.PLACE

    def get_moves_to_apply(self, move, game):
        if move.destinationSquare not in game.squaresToBePlaced:
            raise InvalidMoveException(move, f"Square {move.destinationSquare} is not available to be placed!")

        if not self.__is_square_in_setup_zone_for_color(move.piece.color, move.destinationSquare):
            raise InvalidMoveException(move, f"{move.piece.color} pieces cannot be placed at {move.destinationSquare}!")

        for p in game.possiblePiecesToBePlaced:
            if move.piece == p:
                break
        else:
            raise InvalidMoveException(move, f"That piece is not available to be placed!")

        additional_necessary_placements = self.__get_additional_necessary_placements(move, game)
        return [move, *additional_necessary_placements]

    def apply_game_updates_for_moves(self, moves, game):
        square_removals = [move.destinationSquare for move in moves]
        piece_removals = PlaceMoveUpdateService.__get_piece_removal_for_place_moves(moves, moves[0].piece.color)
        piece_additions = [PlaceMoveUpdateService.__get_piece_addition_for_move(move) for move in moves]

        updates = {
            "$pull": {
                "squaresToBePlaced": {"$in": square_removals},
                "possiblePiecesToBePlaced": piece_removals,
            },
            "$push": {
                "pieces": {"$each": piece_additions},
            },
            "$inc": {"lastMove": len(moves)},
            "$currentDate": {"lastUpdateTimestamp": True},
        }

        Game.objects(_id=game.get_id()).update(__raw__=updates)

    def get_move_for_insert(self, move):
        move_piece = Piece(
            color=move.piece.color,
            type=move.piece.type,
        )

        return Move(
            type=MoveType.PLACE,
            destinationSquare=move.destinationSquare,
            gameUuid=move.gameUuid,
            index=move.index,
            piece=move_piece,
        )

    @staticmethod
    def __get_piece_removal_for_place_moves(moves, color):
        return {
            "$and": [
                {"color": color},
                {"$or": [
                    move.piece.to_dict("type", "index") for move in moves
                ]},
            ],
        }

    @staticmethod
    def __get_piece_addition_for_move(move):
        return Piece(
            color=move.piece.color,
            type=move.piece.type,
            square=move.destinationSquare,
        ).to_dict("color", "type", "square")

    def __get_additional_necessary_placements(self, last_move, game):
        """
        Applies any additional place moves if they are inevitable, for instance, if there are only pieces of a single type
        remaining, or if the user has only one piece left to place, the user has no choice where things are going to be placed
        so it may as well happen automatically

        :param game: The game to which moves are being applied
        :param last_move: The move that was just performed
        """
        piece_color = last_move.piece.color

        def piece_filter(piece):
            return piece.color == piece_color and piece.index != last_move.piece.index

        def square_filter(square):
            return square != last_move.destinationSquare and self.__is_square_in_setup_zone_for_color(
                piece_color,
                square,
            )

        players_other_pieces = list(filter(piece_filter, game.possiblePiecesToBePlaced))
        players_other_squares = list(filter(square_filter, game.squaresToBePlaced))

        if len(players_other_pieces) == 0:
            return []

        # Otherwise, see if the only remaining pieces for that color are of the same type, then they can all be
        # placed in remaining spots for the user
        piece_type = players_other_pieces[0].type
        for piece in players_other_pieces:
            if piece.type != piece_type:
                return []

        return PlaceMoveUpdateService.__build_place_moves_for_pieces(players_other_pieces, players_other_squares, game)

    @staticmethod
    def __build_place_moves_for_pieces(placers_other_pieces, players_other_squares, game):
        def build_move(idx, piece):
            return Move(
                type=MoveType.PLACE,
                piece=piece,
                destinationSquare=players_other_squares[idx],
            )

        return [
            build_move(idx, piece) for idx, piece in enumerate(placers_other_pieces)
        ]

    def __is_square_in_setup_zone_for_color(self, color, square):
        return square in self.__setup_squares_for_color[color]
