-- MARKER_E065_REVERT beta-two-side-friends

DELETE FROM `rbac_default_permissions` WHERE `permissionId` = 29 AND `realmId` = 2;
