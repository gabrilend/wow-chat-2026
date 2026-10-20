-- MARKER_E064_REVERT beta-two-side-who

DELETE FROM `rbac_default_permissions` WHERE `permissionId` = 28 AND `realmId` = 2;
