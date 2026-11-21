extends Node
## Global signal bus so UI and logic stay apart.
## Rule: logic changes state first, then emits. The UI only listens and never changes game state.

signal battle_started(enemy_id: String)
signal round_started(round_number: int)
## The battle moved between phases (BattleController.State: deal, round, surprise, resolve, end).
signal battle_phase_changed(phase: int)
signal card_dealt(who: String, card: Card)
signal card_removed(who: String, card: Card)
signal card_played(card: Card)
signal total_changed(who: String, total: int)
signal hand_changed()
signal hp_changed(who: String, hp: int, max_hp: int)
signal timer_changed(seconds_left: float)
signal intent_changed(enemy_id: String, percent: float)
## The intent bar is about to fill: an attack is coming (which one is never revealed).
signal attack_incoming(enemy_id: String)
signal surprise_attack(enemy_id: String, kind: String)
signal surprise_blocked(enemy_id: String, kind: String)
signal peeked(card: Card)
signal round_resolved(result: Dictionary)
signal boss_phase_changed(phase: int)
signal battle_won(enemy_id: String)
signal battle_lost(enemy_id: String)
signal message(text: String)
