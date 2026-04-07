# mod-talent-bonus
# Adds bonus talent points at 33% and 66% XP progress within each level.
# Issue 120: talent-points-level-20-cap

CollectSourceFiles(
  ${CMAKE_CURRENT_SOURCE_DIR}
  PRIVATE_SOURCES
)

AddModuleSource("${PRIVATE_SOURCES}")
