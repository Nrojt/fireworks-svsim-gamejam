extends Node
# Global signal bus. Only for cross-system events

signal firework_ignited
signal firework_exploded
signal obstacle_destroyed(obstacle: ObstacleBase)
signal round_ended(won: bool, money_leftover: int, obstacle_points: int, total_score: int, obstacles_destroyed: int, obstacles_total: int)
