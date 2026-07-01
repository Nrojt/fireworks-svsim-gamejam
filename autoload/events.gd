extends Node
# Global signal bus. Only cross-system events live here — the kind that need to
# travel between unrelated parts of the tree. Keep it small; for everything else
# prefer the owning system's own signals (e.g. ShopManager.money_changed).

signal firework_ignited
signal firework_exploded
signal obstacle_destroyed(obstacle: ObstacleBase)
signal round_ended(won: bool, money_leftover: int, obstacle_points: int, total_score: int, obstacles_destroyed: int, obstacles_total: int)
