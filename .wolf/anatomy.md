# anatomy.md

> Auto-maintained by OpenWolf. Last scanned: 2026-08-28T20:04:23.197Z
> Files: 535 tracked | Anatomy hits: 0 | Misses: 0

## ../../../Users/JArjona/.claude/projects/C--data-src-cmms/memory/

- `atlas-cmms-azure-infrastructure.md` (~1118 tok)
- `atlas-cmms-fork-and-release-process.md` (~695 tok)
- `atlas-cmms-internal-build-state.md` (~523 tok)
- `MEMORY.md` — Memory index (~245 tok)

## ./

- `.dockerignore` — Docker ignore rules (~123 tok)
- `.easignore` (~70 tok)
- `.gitignore` — Git ignore rules (~102 tok)
- `azure-pipelines.yml` — Atlas CMMS — Enerkem release pipeline (~4030 tok)
- `CLAUDE.md` — OpenWolf (~1987 tok)
- `cmms.service` (~553 tok)
- `COMMERCIAL_LICENSE.MD` — Atlas CMMS Commercial License Agreement (~2818 tok)
- `dev.env` — ────────────────────────────────────────────────────────────────────────── (~789 tok)
- `DEVELOPMENT-STATUS.md` — Development Status — Atlas CMMS internal build (Entra SSO + single-jar + AGPL) (~7145 tok)
- `docker-compose.yml` — Docker Compose services (~1487 tok)
- `GCP-setup.md` — GCP Setup tutorial (~181 tok)
- `LICENSE` — Project license (~9382 tok)
- `pom.xml` — Maven project configuration (~354 tok)
- `README.MD` — ⚡ **Features** (~4851 tok)
- `REQUIREMENTS.md` — REQUIREMENTS.md — what the pipeline and the infrastructure need from you (~3093 tok)
- `Security.md` — Security Policy (~549 tok)
- `UPSTREAM_VERSION` (~2 tok)

## .azure/

- `steps-deploy.yml` — Shared deploy steps for one environment: apply the OpenTofu config, then (~1295 tok)

## .claude/

- `settings.json` (~441 tok)
- `settings.local.json` (~30 tok)

## .claude/rules/

- `openwolf.md` (~313 tok)

## .github/

- `FUNDING.yml` (~14 tok)

## .github/workflows/

- `push-docker.yml` — CI: Build and Push Docker Images (~673 tok)

## api/

- `.gitignore` — Git ignore rules (~368 tok)
- `.trivyignore` (~35 tok)
- `api.iml` (~77 tok)
- `CHANGELOG.md` — Change log (~74 tok)
- `CONTRIBUTING.md` — Guidance on how to contribute (~179 tok)
- `Dockerfile` — Docker container definition (~684 tok)
- `mvnw.cmd` (~1846 tok)
- `pom.xml` — Maven project configuration (~4610 tok)
- `README.md` — Project documentation (~149 tok)
- `system.properties` (~7 tok)

## api/.mvn/wrapper/

- `maven-wrapper.jar` (~14976 tok)
- `maven-wrapper.properties` (~63 tok)

## api/.qwen/

- `settings.json` (~40 tok)
- `settings.json.orig` (~20 tok)

## api/scripts/

- `generate-liquibase.js` — fs: parseArgs, showHelp, formatDate + 4 more (~1832 tok)
- `generate-template.js` — fs: processTemplate, toPascalCase, toCamelCase + 4 more (~1200 tok)

## api/src/main/java/com/grash/

- `ApiApplication.java` — ApiApplication: main, afterSingletonsInstantiated (~1998 tok)

## api/src/main/java/com/grash/advancedsearch/

- `FilterField.java` — Class: FilterField (~369 tok)
- `SearchCriteria.java` — SearchCriteria: filterCompany, filterCreatedBy, clone (~587 tok)
- `SearchOperation.java` — SearchOperation: getDataOption, getSimpleOperation (~547 tok)
- `SpecificationBuilder.java` — SpecificationBuilder: build (~444 tok)
- `WrapperSpecification.java` — WrapperSpecification: toPredicate (~2196 tok)

## api/src/main/java/com/grash/advancedsearch/pagination/

- `DataTablePagination.java` — DataTablePagination: paginationStreamPagination (~224 tok)
- `PageInfo.java` — Class: PageInfo (~138 tok)

## api/src/main/java/com/grash/aspect/

- `TenantAspect.java` — Component: TenantAspect (~911 tok)

## api/src/main/java/com/grash/configuration/

- `AsyncConfig.java` — Configuration: AsyncConfig (~228 tok)
- `AuditConfig.java` — Configuration: AuditConfig (~432 tok)
- `CacheConfig.java` — Configuration: CacheConfig (~415 tok)
- `EmailConfiguration.java` — EmailConfiguration: templateSimpleMessage, emailTemplateResolver, thymeleafTemplateEngine, emailMessageSource (~549 tok)
- `LdapSecurityConfig.java` — Configuration: LdapSecurityConfig (~2262 tok)
- `OAuth2ClientRegistrationConfig.java` — Configuration: OAuth2ClientRegistrationConfig (~1004 tok)
- `OpenApiConfig.java` — Configuration: OpenApiConfig (~12589 tok)
- `QuartzConfig.java` — Configuration: QuartzConfig (~270 tok)
- `SwaggerConfig.java` — Configuration: SwaggerConfig (~147 tok)
- `SwaggerSecurityConfig.java` — ", "/v3/api-docs/**", "/api-docs.html") (~220 tok)
- `WebMvcConfig.java` — Configuration: WebMvcConfig (~572 tok)
- `WebSecurityConfig.java` — ").permitAll() (~2518 tok)
- `WebSocketConfig.java` — Configuration: WebSocketConfig (~323 tok)

## api/src/main/java/com/grash/controller/

- `AdditionalCostController.java` — RestController: AdditionalCostController (6 endpoints) (~1625 tok)
- `ApiKeyController.java` — RestController: ApiKeyController (5 endpoints) (~984 tok)
- `AssetCategoryController.java` — RestController: AssetCategoryController (6 endpoints) (~1394 tok)
- `AssetController.java` — RestController: AssetController (11 endpoints) (~4756 tok)
- `AssetDowntimeController.java` — RestController: AssetDowntimeController (6 endpoints) (~1642 tok)
- `AuthController.java` — RestController: AuthController (15 endpoints) (~2937 tok)
- `ChecklistController.java` — RestController: ChecklistController (6 endpoints) (~1474 tok)
- `CommentController.java` — RestController: CommentController (7 endpoints) (~1570 tok)
- `CompanyController.java` — RestController: CompanyController (3 endpoints) (~884 tok)
- `CompanySettingsController.java` — RestController: CompanySettingsController (2 endpoints) (~525 tok)
- `CostCategoryController.java` — RestController: CostCategoryController (6 endpoints) (~1596 tok)
- `CurrencyController.java` — RestController: CurrencyController (6 endpoints) (~1046 tok)
- `CustomerController.java` — RestController: CustomerController (7 endpoints) (~1699 tok)
- `CustomFieldController.java` — RestController: CustomFieldController (7 endpoints) (~1998 tok)
- `DemoController.java` — RestController: DemoController (3 endpoints) (~3096 tok)
- `DeprecationController.java` — RestController: DeprecationController (5 endpoints) (~964 tok)
- `ExportController.java` — RestController: ExportController (7 endpoints) (~1538 tok)
- `FieldConfigurationController.java` — RestController: FieldConfigurationController (2 endpoints) (~923 tok)
- `FileController.java` — RestController: FileController (9 endpoints) (~3016 tok)
- `FloorPlanController.java` — RestController: FloorPlanController (6 endpoints) (~1480 tok)
- `GeneralPreferencesController.java` — RestController: GeneralPreferencesController (4 endpoints) (~966 tok)
- `HealthCheckController.java` — RestController: HealthCheckController (2 endpoints) (~454 tok)
- `ImportController.java` — RestController: ImportController (8 endpoints) (~2724 tok)
- `InstanceConfigController.java` — RestController: InstanceConfigController (2 endpoints) (~196 tok)
- `LaborController.java` — RestController: LaborController (7 endpoints) (~1951 tok)
- `LicenseController.java` — RestController: LicenseController (2 endpoints) (~183 tok)
- `LocationController.java` — RestController: LocationController (10 endpoints) (~3115 tok)
- `MeterCategoryController.java` — RestController: MeterCategoryController (6 endpoints) (~1437 tok)
- `MeterController.java` — RestController: MeterController (8 endpoints) (~2448 tok)
- `MultiPartsController.java` — RestController: MultiPartsController (7 endpoints) (~1747 tok)
- `NotificationController.java` — RestController: NotificationController (7 endpoints) (~1638 tok)
- `PaddleController.java` — RestController: PaddleController (5 endpoints) (~1258 tok)
- `PartCategoryController.java` — RestController: PartCategoryController (6 endpoints) (~1380 tok)
- `PartController.java` — RestController: PartController (7 endpoints) (~2310 tok)
- `PartQuantityController.java` — RestController: PartQuantityController (9 endpoints) (~3579 tok)
- `PreventiveMaintenanceController.java` — RestController: PreventiveMaintenanceController (7 endpoints) (~2156 tok)
- `PurchaseOrderCategoryController.java` — RestController: PurchaseOrderCategoryController (6 endpoints) (~1563 tok)
- `PurchaseOrderController.java` — RestController: PurchaseOrderController (7 endpoints) (~4030 tok)
- `ReadingController.java` — RestController: ReadingController (5 endpoints) (~2226 tok)
- `RelationController.java` — RestController: RelationController (7 endpoints) (~1299 tok)
- `RequestController.java` — RestController: RequestController (8 endpoints) (~6093 tok)
- `RequestPortalController.java` — RestController: RequestPortalController (7 endpoints) (~1112 tok)
- `ReviewController.java` — RestController: ReviewController (7 endpoints) (~967 tok)
- `RoleController.java` — RestController: RoleController (6 endpoints) (~1322 tok)
- `ScheduleController.java` — RestController: ScheduleController (5 endpoints) (~1132 tok)
- `ShiftConfigurationController.java` — RestController: ShiftConfigurationController (3 endpoints) (~955 tok)
- `SourceCodeController.java` — Serves the complete corresponding source code of this running version, as (~534 tok)
- `SpaForwardController.java` — Serves the React single-page application that is bundled into this jar (~302 tok)
- `SubscriptionController.java` — RestController: SubscriptionController (6 endpoints) (~2375 tok)
- `SubscriptionPlanController.java` — RestController: SubscriptionPlanController (6 endpoints) (~1099 tok)
- `TaskBaseController.java` — RestController: TaskBaseController (5 endpoints) (~1019 tok)
- `TaskController.java` — RestController: TaskController (8 endpoints) (~2971 tok)
- `TeamController.java` — RestController: TeamController (7 endpoints) (~1574 tok)
- `TimeCategoryController.java` — RestController: TimeCategoryController (6 endpoints) (~1434 tok)
- `UiConfigurationController.java` — RestController: UiConfigurationController (2 endpoints) (~566 tok)
- `UserController.java` — RestController: UserController (11 endpoints) (~3693 tok)
- `UserSettingsController.java` — RestController: UserSettingsController (3 endpoints) (~716 tok)
- `VendorController.java` — RestController: VendorController (7 endpoints) (~1681 tok)
- `WebhookController.java` — Handle regular subscription updates (plan changes, quantity changes, etc.) (~6257 tok)
- `WebhookEndpointController.java` — RestController: WebhookEndpointController (6 endpoints) (~3113 tok)
- `WorkflowController.java` — RestController: WorkflowController (6 endpoints) (~1831 tok)
- `WorkloadController.java` — RestController: WorkloadController (4 endpoints) (~1299 tok)
- `WorkOrderCategoryController.java` — RestController: WorkOrderCategoryController (6 endpoints) (~1492 tok)
- `WorkOrderConfigurationController.java` — RestController: WorkOrderConfigurationController (2 endpoints) (~571 tok)
- `WorkOrderController.java` — RestController: WorkOrderController (10 endpoints) (~8938 tok)
- `WorkOrderHistoryController.java` — RestController: WorkOrderHistoryController (3 endpoints) (~801 tok)
- `WorkOrderMeterTriggerController.java` — RestController: WorkOrderMeterTriggerController (6 endpoints) (~1480 tok)
- `WorkOrderRequestConfigurationController.java` — RestController: WorkOrderRequestConfigurationController (2 endpoints) (~618 tok)

## api/src/main/java/com/grash/controller/analytics/

- `AssetAnalyticsController.java` — RestController: AssetAnalyticsController (8 endpoints) (~6548 tok)
- `PartAnalyticsController.java` — RestController: PartAnalyticsController (7 endpoints) (~3831 tok)
- `RequestAnalyticsController.java` — RestController: RequestAnalyticsController (6 endpoints) (~3725 tok)
- `UserAnalyticsController.java` — RestController: UserAnalyticsController (3 endpoints) (~1210 tok)
- `WOAnalyticsController.java` — RestController: WOAnalyticsController (6 endpoints) (~11069 tok)

## api/src/main/java/com/grash/controller/zapier/

- `ZapierSampleController.java` — RestController: ZapierSampleController (2 endpoints) (~17114 tok)

## api/src/main/java/com/grash/dto/

- `AdditionalCostPatchDTO.java` — Class: AdditionalCostPatchDTO (~105 tok)
- `AssetDowntimePatchDTO.java` — Class: AssetDowntimePatchDTO (~136 tok)
- `AssetMiniDTO.java` — Class: AssetMiniDTO (~188 tok)
- `AssetPatchDTO.java` — Class: AssetPatchDTO (~1294 tok)
- `AssetPostDTO.java` — Class: AssetPostDTO (~157 tok)
- `AssetShowDTO.java` — Class: AssetShowDTO (~1057 tok)
- `AuditShowDTO.java` — Class: AuditShowDTO (~203 tok)
- `AuthResponse.java` — Class: AuthResponse (~158 tok)
- `BrandConfig.java` — Class: BrandConfig (~260 tok)
- `CalendarEvent.java` — Class: CalendarEvent (~156 tok)
- `CategoryMiniDTO.java` — Class: CategoryMiniDTO (~140 tok)
- `CategoryPatchDTO.java` — Class: CategoryPatchDTO (~135 tok)
- `CategoryPostDTO.java` — Class: CategoryPostDTO (~132 tok)
- `ChecklistMiniDTO.java` — Class: ChecklistMiniDTO (~124 tok)
- `ChecklistPatchDTO.java` — Class: ChecklistPatchDTO (~187 tok)
- `ChecklistPostDTO.java` — Class: ChecklistPostDTO (~244 tok)
- `CompanyPatchDTO.java` — Class: CompanyPatchDTO (~302 tok)
- `CompanyShowDTO.java` — Class: CompanyShowDTO (~394 tok)
- `CurrencyPatchDTO.java` — Class: CurrencyPatchDTO (~117 tok)
- `CustomerMiniDTO.java` — Class: CustomerMiniDTO (~108 tok)
- `CustomerPatchDTO.java` — Class: CustomerPatchDTO (~370 tok)
- `CustomerPostDTO.java` — Class: CustomerPostDTO (~161 tok)
- `CustomerShowDTO.java` — Class: CustomerShowDTO (~420 tok)
- `DateRange.java` — Class: DateRange (~147 tok)
- `DeprecationPatchDTO.java` — Class: DeprecationPatchDTO (~218 tok)
- `EmailAttachmentDTO.java` — Class: EmailAttachmentDTO (~182 tok)
- `FeedbackDTO.java` — Class: FeedbackDTO (~33 tok)
- `FieldConfigurationPatchDTO.java` — Class: FieldConfigurationPatchDTO (~112 tok)
- `FileMiniDTO.java` — Class: FileMiniDTO (~127 tok)
- `FilePatchDTO.java` — Class: FilePatchDTO (~105 tok)
- `FileShowDTO.java` — Class: FileShowDTO (~260 tok)
- `FileThumbnailDTO.java` — Class: FileThumbnailDTO (~89 tok)
- `FloorPlanPatchDTO.java` — Class: FloorPlanPatchDTO (~168 tok)
- `FloorPlanShowDTO.java` — Class: FloorPlanShowDTO (~160 tok)
- `GeneralPreferencesPatchDTO.java` — GeneralPreferencesPatchDTO: setDaysBeforePrevMaintNotification (~728 tok)
- `IdDTO.java` — Class: IdDTO (~79 tok)
- `InstanceConfig.java` — Class: InstanceConfig (~52 tok)
- `LaborPatchDTO.java` — Class: LaborPatchDTO (~264 tok)
- `LdapLoginRequest.java` — Class: LdapLoginRequest (~215 tok)
- `LocationMiniDTO.java` — Class: LocationMiniDTO (~173 tok)
- `LocationPatchDTO.java` — Class: LocationPatchDTO (~722 tok)
- `LocationPostDTO.java` — Class: LocationPostDTO (~161 tok)
- `LocationShowDTO.java` — Class: LocationShowDTO (~563 tok)
- `MeterMiniDTO.java` — Class: MeterMiniDTO (~106 tok)
- `MeterPatchDTO.java` — Class: MeterPatchDTO (~478 tok)
- `MeterPostDTO.java` — Class: MeterPostDTO (~157 tok)
- `MeterShowDTO.java` — Class: MeterShowDTO (~437 tok)
- `MultiPartsMiniDTO.java` — Class: MultiPartsMiniDTO (~141 tok)
- `MultiPartsPatchDTO.java` — Class: MultiPartsPatchDTO (~173 tok)
- `MultiPartsShowDTO.java` — Class: MultiPartsShowDTO (~141 tok)
- `NotificationPatchDTO.java` — Class: NotificationPatchDTO (~102 tok)
- `PartMiniDTO.java` — Class: PartMiniDTO (~220 tok)
- `PartPatchDTO.java` — Class: PartPatchDTO (~909 tok)
- `PartPostDTO.java` — Class: PartPostDTO (~156 tok)
- `PartQuantityCompletePatchDTO.java` — Class: PartQuantityCompletePatchDTO (~216 tok)
- `PartQuantityPatchDTO.java` — Class: PartQuantityPatchDTO (~150 tok)
- `PartQuantityShowDTO.java` — Class: PartQuantityShowDTO (~132 tok)
- `PartShowDTO.java` — Class: PartShowDTO (~648 tok)
- `PreventiveMaintenanceMiniDTO.java` — Class: PreventiveMaintenanceMiniDTO (~158 tok)
- `PreventiveMaintenancePatchDTO.java` — Class: PreventiveMaintenancePatchDTO (~109 tok)
- `PreventiveMaintenancePostDTO.java` — PreventiveMaintenancePostDTO: getCustomFieldValues (~493 tok)
- `PreventiveMaintenanceShowDTO.java` — Class: PreventiveMaintenanceShowDTO (~203 tok)
- `PurchaseOrderMiniDTO.java` — Class: PurchaseOrderMiniDTO (~109 tok)
- `PurchaseOrderPatchDTO.java` — Class: PurchaseOrderPatchDTO (~629 tok)
- `PurchaseOrderShowDTO.java` — Class: PurchaseOrderShowDTO (~680 tok)
- `PushTokenPayload.java` — Class: PushTokenPayload (~105 tok)
- `ReadingPatchDTO.java` — Class: ReadingPatchDTO (~149 tok)
- `RelationPatchDTO.java` — Class: RelationPatchDTO (~165 tok)
- `RelationPostDTO.java` — Class: RelationPostDTO (~220 tok)
- `RequestApproveDTO.java` — Class: RequestApproveDTO (~108 tok)
- `RequestMiniDTO.java` — Class: RequestMiniDTO (~134 tok)
- `RequestPatchDTO.java` — Class: RequestPatchDTO (~182 tok)
- `RequestPostDTO.java` — Class: RequestPostDTO (~126 tok)
- `RequestShowDTO.java` — Class: RequestShowDTO (~354 tok)
- `RolePatchDTO.java` — Class: RolePatchDTO (~349 tok)
- `SchedulePatchDTO.java` — Class: SchedulePatchDTO (~327 tok)
- `SignupSuccessResponse.java` — Class: SignupSuccessResponse (~166 tok)
- `SubscriptionPatchDTO.java` — Class: SubscriptionPatchDTO (~195 tok)
- `SubscriptionPlanPatchDTO.java` — Class: SubscriptionPlanPatchDTO (~227 tok)
- `SuccessResponse.java` — Class: SuccessResponse (~138 tok)
- `SuperAccountRelationDTO.java` — Class: SuperAccountRelationDTO (~151 tok)
- `TaskBaseDTO.java` — Class: TaskBaseDTO (~273 tok)
- `TaskBasePatchDTO.java` — Class: TaskBasePatchDTO (~93 tok)
- `TaskBaseShowDTO.java` — Class: TaskBaseShowDTO (~257 tok)
- `TaskOptionPatchDTO.java` — Class: TaskOptionPatchDTO (~94 tok)
- `TaskOptionShowDTO.java` — Class: TaskOptionShowDTO (~107 tok)
- `TaskPatchDTO.java` — Class: TaskPatchDTO (~145 tok)
- `TaskShowDTO.java` — Class: TaskShowDTO (~332 tok)
- `TeamMiniDTO.java` — Class: TeamMiniDTO (~134 tok)
- `TeamPatchDTO.java` — Class: TeamPatchDTO (~184 tok)
- `TeamShowDTO.java` — Class: TeamShowDTO (~177 tok)
- `UiConfigurationPatchDTO.java` — Class: UiConfigurationPatchDTO (~169 tok)
- `UpdatePasswordRequest.java` — Class: UpdatePasswordRequest (~191 tok)
- `UserInvitationDTO.java` — Class: UserInvitationDTO (~215 tok)
- `UserInvitationMiniDTO.java` — Class: UserInvitationMiniDTO (~155 tok)
- `UserLoginRequest.java` — Class: UserLoginRequest (~156 tok)
- `UserMiniDTO.java` — Class: UserMiniDTO (~219 tok)
- `UserPatchDTO.java` — Class: UserPatchDTO (~297 tok)
- `UserResponseDTO.java` — Class: UserResponseDTO (~709 tok)
- `UserSignupRequest.java` — Class: UserSignupRequest (~313 tok)
- `UtmParams.java` — UtmParams: hasAnyParam (~446 tok)
- `VendorMiniDTO.java` — Class: VendorMiniDTO (~130 tok)
- `VendorPatchDTO.java` — Class: VendorPatchDTO (~248 tok)
- `VendorPostDTO.java` — Class: VendorPostDTO (~158 tok)
- `VendorShowDTO.java` — Class: VendorShowDTO (~367 tok)
- `WorkflowActionPatchDTO.java` — Class: WorkflowActionPatchDTO (~379 tok)
- `WorkflowActionPostDTO.java` — Class: WorkflowActionPostDTO (~403 tok)
- `WorkflowActionShowDTO.java` — Class: WorkflowActionShowDTO (~619 tok)
- `WorkflowConditionPatchDTO.java` — Class: WorkflowConditionPatchDTO (~485 tok)
- `WorkflowConditionPostDTO.java` — Class: WorkflowConditionPostDTO (~530 tok)
- `WorkflowConditionShowDTO.java` — Class: WorkflowConditionShowDTO (~734 tok)
- `WorkflowPatchDTO.java` — Class: WorkflowPatchDTO (~199 tok)
- `WorkflowPostDTO.java` — Class: WorkflowPostDTO (~287 tok)
- `WorkflowShowDTO.java` — Class: WorkflowShowDTO (~291 tok)
- `WorkOrderBaseMiniDTO.java` — Class: WorkOrderBaseMiniDTO (~287 tok)
- `WorkOrderBasePatchDTO.java` — Class: WorkOrderBasePatchDTO (~814 tok)
- `WorkOrderBaseShowDTO.java` — Class: WorkOrderBaseShowDTO (~651 tok)
- `WorkOrderChangeStatusDTO.java` — Class: WorkOrderChangeStatusDTO (~182 tok)
- `WorkOrderHistoryShowDTO.java` — Class: WorkOrderHistoryShowDTO (~146 tok)
- `WorkOrderMeterTriggerPatchDTO.java` — Class: WorkOrderMeterTriggerPatchDTO (~250 tok)
- `WorkOrderMeterTriggerPostDTO.java` — Class: WorkOrderMeterTriggerPostDTO (~138 tok)
- `WorkOrderMeterTriggerShowDTO.java` — Class: WorkOrderMeterTriggerShowDTO (~260 tok)

## api/src/main/java/com/grash/dto/analytics/assets/

- `AssetOverview.java` — Class: AssetOverview (~230 tok)
- `AssetsCosts.java` — Class: AssetsCosts (~181 tok)
- `AssetStats.java` — Class: AssetStats (~180 tok)
- `DowntimesAndCostsByAsset.java` — Class: DowntimesAndCostsByAsset (~178 tok)
- `DowntimesByAsset.java` — Class: DowntimesByAsset (~168 tok)
- `DowntimesByDate.java` — Class: DowntimesByDate (~181 tok)
- `DowntimesMeantimeByDate.java` — Class: DowntimesMeantimeByDate (~157 tok)
- `Meantimes.java` — Class: Meantimes (~155 tok)
- `MTBFByAsset.java` — Class: MTBFByAsset (~150 tok)
- `RepairTimeByAsset.java` — Class: RepairTimeByAsset (~148 tok)
- `TimeCostByAsset.java` — Class: TimeCostByAsset (~167 tok)

## api/src/main/java/com/grash/dto/analytics/parts/

- `PartConsumptionByCategory.java` — Class: PartConsumptionByCategory (~152 tok)
- `PartConsumptionByWOCategory.java` — Class: PartConsumptionByWOCategory (~155 tok)
- `PartConsumptionsByAsset.java` — Class: PartConsumptionsByAsset (~148 tok)
- `PartConsumptionsByMonth.java` — Class: PartConsumptionsByMonth (~152 tok)
- `PartConsumptionsByPart.java` — Class: PartConsumptionsByPart (~147 tok)
- `PartStats.java` — Class: PartStats (~154 tok)

## api/src/main/java/com/grash/dto/analytics/requests/

- `CountByCategory.java` — Class: CountByCategory (~149 tok)
- `RequestsByMonth.java` — Class: RequestsByMonth (~153 tok)
- `RequestsResolvedByDate.java` — Class: RequestsResolvedByDate (~187 tok)
- `RequestStats.java` — Class: RequestStats (~204 tok)
- `RequestStatsByPriority.java` — Class: RequestStatsByPriority (~279 tok)

## api/src/main/java/com/grash/dto/analytics/users/

- `UserWOStats.java` — Class: UserWOStats (~153 tok)
- `WOStatsByDay.java` — Class: WOStatsByDay (~182 tok)

## api/src/main/java/com/grash/dto/analytics/workOrders/

- `IncompleteWOByAsset.java` — Class: IncompleteWOByAsset (~180 tok)
- `IncompleteWOByUser.java` — Class: IncompleteWOByUser (~177 tok)
- `MobileWOStats.java` — Class: MobileWOStats (~261 tok)
- `MobileWOStatsExtended.java` — Class: MobileWOStatsExtended (~224 tok)
- `WOCostsAndTime.java` — Class: WOCostsAndTime (~238 tok)
- `WOCostsByDate.java` — Class: WOCostsByDate (~198 tok)
- `WOCountByCategory.java` — Class: WOCountByCategory (~152 tok)
- `WOCountByUser.java` — Class: WOCountByUser (~147 tok)
- `WOCountByWeek.java` — Class: WOCountByWeek (~195 tok)
- `WOHours.java` — Class: WOHours (~147 tok)
- `WOIncompleteStats.java` — Class: WOIncompleteStats (~152 tok)
- `WOStats.java` — Class: WOStats (~222 tok)
- `WOStatsByPriority.java` — Class: WOStatsByPriority (~308 tok)
- `WOStatuses.java` — Class: WOStatuses (~219 tok)
- `WOStatusesByDate.java` — Class: WOStatusesByDate (~151 tok)
- `WOTimeByWeek.java` — Class: WOTimeByWeek (~171 tok)

## api/src/main/java/com/grash/dto/apiKey/

- `ApiKeyCriteria.java` — Class: ApiKeyCriteria (~64 tok)
- `ApiKeyPatchDTO.java` — Class: ApiKeyPatchDTO (~112 tok)
- `ApiKeyPostDTO.java` — Class: ApiKeyPostDTO (~97 tok)
- `ApiKeyShowDTO.java` — Class: ApiKeyShowDTO (~216 tok)

## api/src/main/java/com/grash/dto/checkout/

- `CheckoutRequest.java` — CheckoutRequest.java (~188 tok)
- `CheckoutResponse.java` — CheckoutResponse.java (~114 tok)

## api/src/main/java/com/grash/dto/comment/

- `CommentCount.java` — Class: CommentCount (~58 tok)
- `CommentCriteria.java` — Class: CommentCriteria (~55 tok)
- `CommentPatchDTO.java` — Class: CommentPatchDTO (~176 tok)
- `CommentPostDTO.java` — Class: CommentPostDTO (~190 tok)
- `CommentShowDTO.java` — Class: CommentShowDTO (~213 tok)

## api/src/main/java/com/grash/dto/cutomField/

- `CustomFieldPatchDTO.java` — Class: CustomFieldPatchDTO (~239 tok)
- `CustomFieldPostDTO.java` — Class: CustomFieldPostDTO (~341 tok)
- `CustomFieldShowDTO.java` — Class: CustomFieldShowDTO (~356 tok)
- `CustomFieldValuePostDTO.java` — Class: CustomFieldValuePostDTO (~46 tok)
- `CustomFieldValueShowDTO.java` — Class: CustomFieldValueShowDTO (~52 tok)

## api/src/main/java/com/grash/dto/fastSpring/

- `Account.java` — Class: Account (~246 tok)
- `Address.java` — Class: Address (~184 tok)
- `CancellationSetting.java` — Class: CancellationSetting (~156 tok)
- `Contact.java` — Class: Contact (~189 tok)
- `Customer.java` — Class: Customer (~202 tok)
- `Event.java` — Class: Event (~205 tok)
- `Fulfillments.java` — Class: Fulfillments (~63 tok)
- `Instruction.java` — Class: Instruction (~1222 tok)
- `Item.java` — Class: Item (~477 tok)
- `Lookup.java` — Class: Lookup (~78 tok)
- `Payment.java` — Class: Payment (~116 tok)
- `PaymentOverdue.java` — Class: PaymentOverdue (~165 tok)
- `PaymentReminder.java` — Class: PaymentReminder (~119 tok)
- `Recipient.java` — Class: Recipient (~83 tok)
- `Recipient2.java` — Class: Recipient2 (~255 tok)
- `Subscription.java` — Class: Subscription (~2604 tok)
- `Tags.java` — Class: Tags (~90 tok)
- `TrialReminder.java` — Class: TrialReminder (~123 tok)
- `WebhookPayload.java` — Class: WebhookPayload (~107 tok)
- `Withholdings.java` — Class: Withholdings (~92 tok)

## api/src/main/java/com/grash/dto/fastSpring/payloads/

- `DeactivatedPayload.java` — Class: DeactivatedPayload (~1710 tok)
- `Order.java` — Class: Order (~1308 tok)
- `ResumePayload.java` — Class: ResumePayload (~309 tok)
- `SubscriptionCharge.java` — Class: SubscriptionCharge (~367 tok)
- `SubscriptionPayload.java` — Class: SubscriptionPayload (~2844 tok)

## api/src/main/java/com/grash/dto/imports/

- `AssetImportDTO.java` — Class: AssetImportDTO (~753 tok)
- `ImportResponse.java` — Class: ImportResponse (~153 tok)
- `LocationImportDTO.java` — Class: LocationImportDTO (~426 tok)
- `MeterImportDTO.java` — Class: MeterImportDTO (~320 tok)
- `PartImportDTO.java` — Class: PartImportDTO (~563 tok)
- `PreventiveMaintenanceImportDTO.java` — PreventiveMaintenanceImportDTO: getDaysOfWeek (~460 tok)
- `WorkOrderImportDTO.java` — Class: WorkOrderImportDTO (~640 tok)

## api/src/main/java/com/grash/dto/keygen/

- `KeygenLicenseAttributes.java` — Class: KeygenLicenseAttributes (~163 tok)
- `KeygenLicenseData.java` — Class: KeygenLicenseData (~185 tok)
- `KeygenLicenseRelationships.java` — Class: KeygenLicenseRelationships (~161 tok)
- `KeygenLicenseRequest.java` — Class: KeygenLicenseRequest (~122 tok)
- `KeygenLicenseResponse.java` — Class: KeygenLicenseResponse (~150 tok)
- `KeygenLicenseResponseAttributes.java` — Class: KeygenLicenseResponseAttributes (~902 tok)
- `KeygenLicenseResponseData.java` — Class: KeygenLicenseResponseData (~208 tok)
- `KeygenLicenseUpdateAttributes.java` — Class: KeygenLicenseUpdateAttributes (~127 tok)
- `KeygenLicenseUpdateData.java` — Class: KeygenLicenseUpdateData (~151 tok)
- `KeygenLicenseUpdateRequest.java` — Class: KeygenLicenseUpdateRequest (~121 tok)
- `KeygenRelationship.java` — Class: KeygenRelationship (~126 tok)
- `KeygenRelationshipData.java` — Class: KeygenRelationshipData (~146 tok)
- `KeygenUser.java` — Class: KeygenUser (~163 tok)
- `KeygenUserAttributes.java` — Class: KeygenUserAttributes (~149 tok)
- `KeygenUserCreateAttributes.java` — KeygenUserCreateAttributes.java (~207 tok)
- `KeygenUserCreateData.java` — Class: KeygenUserCreateData (~148 tok)
- `KeygenUserCreateRequest.java` — Class: KeygenUserCreateRequest (~119 tok)
- `KeygenUserResponse.java` — Class: KeygenUserResponse (~124 tok)
- `KeygenUserSingleResponse.java` — Class: KeygenUserSingleResponse (~130 tok)
- `KeygenUserUpdateAttributes.java` — Class: KeygenUserUpdateAttributes (~131 tok)
- `KeygenUserUpdateData.java` — Class: KeygenUserUpdateData (~147 tok)
- `KeygenUserUpdateRequest.java` — Class: KeygenUserUpdateRequest (~118 tok)

## api/src/main/java/com/grash/dto/license/

- `DecryptedLicenseData.java` — Represents the decrypted license data from a license.lic file. (~2407 tok)
- `EntitlementAttributes.java` — Class: EntitlementAttributes (~216 tok)
- `EntitlementData.java` — Class: EntitlementData (~186 tok)
- `EntitlementsResponse.java` — Class: EntitlementsResponse (~135 tok)
- `LicenseAttributes.java` — Class: LicenseAttributes (~563 tok)
- `LicenseData.java` — Class: LicenseData (~256 tok)
- `LicenseEntitlement.java` — Enumeration of all available license entitlements representing features (~947 tok)
- `LicenseRelationships.java` — Class: LicenseRelationships (~395 tok)
- `LicenseValidationMeta.java` — Class: LicenseValidationMeta (~162 tok)
- `LicenseValidationRequest.java` — Request DTOs (~135 tok)
- `LicenseValidationResponse.java` — Class: LicenseValidationResponse (~167 tok)
- `LicenseValidationScope.java` — Class: LicenseValidationScope (~131 tok)
- `LicensingState.java` — Class: LicensingState (~301 tok)
- `RelationshipData.java` — Class: RelationshipData (~154 tok)
- `RelationshipLinks.java` — Class: RelationshipLinks (~135 tok)
- `RelationshipObject.java` — Class: RelationshipObject (~170 tok)
- `RelationshipWithMeta.java` — Class: RelationshipWithMeta (~180 tok)
- `SelfHostedPlan.java` — Class: SelfHostedPlan (~270 tok)
- `ValidationMeta.java` — Class: ValidationMeta (~248 tok)
- `ValidationScope.java` — Class: ValidationScope (~132 tok)

## api/src/main/java/com/grash/dto/paddle/

- `Address.java` — Class: Address (~276 tok)
- `AdjustedTotals.java` — Class: AdjustedTotals (~302 tok)
- `BillingCycle.java` — Class: BillingCycle (~120 tok)
- `BillingDetails.java` — Class: BillingDetails (~370 tok)
- `BillingPeriod.java` — Class: BillingPeriod (~157 tok)
- `Card.java` — Class: Card (~236 tok)
- `Checkout.java` — Class: Checkout (~76 tok)
- `LineItem.java` — Class: LineItem (~270 tok)
- `MethodDetails.java` — Class: MethodDetails (~161 tok)
- `PaddleTransactionData.java` — PaddleTransactionData: getCustomerEmail (~998 tok)
- `PaddleWebhookEvent.java` — Webhook DTOs (~252 tok)
- `Payment.java` — Class: Payment (~387 tok)
- `PaymentTerms.java` — Class: PaymentTerms (~120 tok)
- `PayoutTotals.java` — Class: PayoutTotals (~367 tok)
- `Price.java` — Class: Price (~575 tok)
- `Product.java` — Class: Product (~374 tok)
- `Quantity.java` — Class: Quantity (~109 tok)
- `TaxRateUsed.java` — Class: TaxRateUsed (~134 tok)
- `Totals.java` — Class: Totals (~370 tok)
- `TransactionDetails.java` — Class: TransactionDetails (~271 tok)
- `TransactionItem.java` — Class: TransactionItem (~176 tok)
- `TrialPeriod.java` — Class: TrialPeriod (~116 tok)
- `UnitPrice.java` — Class: UnitPrice (~147 tok)
- `UnitPriceOverride.java` — Class: UnitPriceOverride (~173 tok)

## api/src/main/java/com/grash/dto/paddle/subscription/

- `BillingDetails.java` — Class: BillingDetails (~270 tok)
- `BillingPeriod.java` — Class: BillingPeriod (~164 tok)
- `PaddleItem.java` — Class: PaddleItem (~185 tok)
- `PaddlePrice.java` — Class: PaddlePrice (~91 tok)
- `PaddleSubscriptionData.java` — Class: PaddleSubscriptionData (~439 tok)
- `PaddleSubscriptionStatus.java` — Class: PaddleSubscriptionStatus (~90 tok)
- `PaddleSubscriptionWebhookEvent.java` — Class: PaddleSubscriptionWebhookEvent (~229 tok)
- `PaymentTerms.java` — Class: PaymentTerms (~162 tok)
- `ScheduledChange.java` — Class: ScheduledChange (~207 tok)

## api/src/main/java/com/grash/dto/requestPortal/

- `RequestPortalCriteria.java` — Class: RequestPortalCriteria (~72 tok)
- `RequestPortalMiniDTO.java` — Class: RequestPortalMiniDTO (~140 tok)
- `RequestPortalPatchDTO.java` — Class: RequestPortalPatchDTO (~211 tok)
- `RequestPortalPostDTO.java` — Class: RequestPortalPostDTO (~248 tok)
- `RequestPortalPublicDTO.java` — Class: RequestPortalPublicDTO (~340 tok)
- `RequestPortalShowDTO.java` — Class: RequestPortalShowDTO (~265 tok)

## api/src/main/java/com/grash/dto/shiftConfiguration/

- `ShiftConfigurationPatchDTO.java` — Class: ShiftConfigurationPatchDTO (~180 tok)
- `ShiftConfigurationPostDTO.java` — Class: ShiftConfigurationPostDTO (~186 tok)
- `ShiftConfigurationShowDTO.java` — Class: ShiftConfigurationShowDTO (~202 tok)
- `UserShiftDTO.java` — Class: UserShiftDTO (~152 tok)

## api/src/main/java/com/grash/dto/webhook/

- `WebhookEventInfo.java` — Class: WebhookEventInfo (~259 tok)

## api/src/main/java/com/grash/dto/webhookEndpoint/

- `WebhookEndpointCriteria.java` — Class: WebhookEndpointCriteria (~72 tok)
- `WebhookEndpointPatchDTO.java` — Class: WebhookEndpointPatchDTO (~456 tok)
- `WebhookEndpointPostDTO.java` — Class: WebhookEndpointPostDTO (~536 tok)
- `WebhookEndpointShowDTO.java` — Class: WebhookEndpointShowDTO (~550 tok)

## api/src/main/java/com/grash/dto/workOrder/

- `WorkOrderMiniDTO.java` — Class: WorkOrderMiniDTO (~254 tok)
- `WorkOrderPatchDTO.java` — Class: WorkOrderPatchDTO (~273 tok)
- `WorkOrderPostDTO.java` — Class: WorkOrderPostDTO (~163 tok)
- `WorkOrderScheduleDTO.java` — Class: WorkOrderScheduleDTO (~102 tok)
- `WorkOrderShowDTO.java` — Class: WorkOrderShowDTO (~484 tok)

## api/src/main/java/com/grash/dto/workload/

- `UnscheduledWorkOrdersDTO.java` — Class: UnscheduledWorkOrdersDTO (~257 tok)
- `WorkloadDayDTO.java` — Class: WorkloadDayDTO (~256 tok)
- `WorkloadOverviewDTO.java` — Class: WorkloadOverviewDTO (~256 tok)
- `WorkloadScheduleDTO.java` — Class: WorkloadScheduleDTO (~151 tok)
- `WorkloadUserDayDTO.java` — Class: WorkloadUserDayDTO (~242 tok)
- `WorkloadWorkOrderDTO.java` — Class: WorkloadWorkOrderDTO (~275 tok)

## api/src/main/java/com/grash/event/

- `CompanyCreatedEvent.java` — Class: CompanyCreatedEvent (~78 tok)

## api/src/main/java/com/grash/exception/

- `CustomException.java` — CustomException: getMessage, getHttpStatus (~177 tok)
- `GlobalExceptionHandlerController.java` — RestController: GlobalExceptionHandlerController (~1035 tok)

## api/src/main/java/com/grash/factory/

- `MailServiceFactory.java` — Configuration: MailServiceFactory (~236 tok)
- `StorageServiceFactory.java` — Configuration: StorageServiceFactory (~272 tok)

## api/src/main/java/com/grash/job/

- `DeleteDemoCompaniesJob.java` — Component: DeleteDemoCompaniesJob (~306 tok)
- `LdapSyncJob.java` — Component: LdapSyncJob (~248 tok)
- `LdapSyncJobScheduler.java` — Component: LdapSyncJobScheduler (~632 tok)
- `PreventiveMaintenanceNotificationJob.java` — Component: PreventiveMaintenanceNotificationJob (~1012 tok)
- `SubscriptionEndJob.java` — Component: SubscriptionEndJob (~446 tok)
- `WorkOrderCreationJob.java` — Component: WorkOrderCreationJob (~879 tok)

## api/src/main/java/com/grash/mapper/

- `AdditionalCostMapper.java` — Class: AdditionalCostMapper (~140 tok)
- `ApiKeyMapper.java` — Class: ApiKeyMapper (~258 tok)
- `AssetCategoryMapper.java` — Class: AssetCategoryMapper (~133 tok)
- `AssetDowntimeMapper.java` — Class: AssetDowntimeMapper (~137 tok)
- `AssetMapper.java` — Class: AssetMapper (~464 tok)
- `ChecklistMapper.java` — Class: ChecklistMapper (~75 tok)
- `CommentMapper.java` — Class: CommentMapper (~183 tok)
- `CompanyMapper.java` — Class: CompanyMapper (~155 tok)
- `CostCategoryMapper.java` — Class: CostCategoryMapper (~162 tok)
- `CurrencyMapper.java` — Class: CurrencyMapper (~124 tok)
- `CustomerMapper.java` — Class: CustomerMapper (~212 tok)
- `CustomFieldMapper.java` — Class: CustomFieldMapper (~208 tok)
- `CustomFieldValueMapper.java` — Class: CustomFieldValueMapper (~99 tok)
- `DeprecationMapper.java` — Class: DeprecationMapper (~132 tok)
- `FieldConfigurationMapper.java` — Class: FieldConfigurationMapper (~150 tok)
- `FileMapper.java` — FileMapper: toThumbnailDto (~1068 tok)
- `FloorPlanMapper.java` — Class: FloorPlanMapper (~205 tok)
- `GeneralPreferencesMapper.java` — Class: GeneralPreferencesMapper (~150 tok)
- `LaborMapper.java` — Class: LaborMapper (~116 tok)
- `LocationMapper.java` — Class: LocationMapper (~406 tok)
- `MeterCategoryMapper.java` — Class: MeterCategoryMapper (~133 tok)
- `MeterMapper.java` — Class: MeterMapper (~528 tok)
- `MultiPartsMapper.java` — Class: MultiPartsMapper (~193 tok)
- `NotificationMapper.java` — Class: NotificationMapper (~134 tok)
- `PartCategoryMapper.java` — Class: PartCategoryMapper (~131 tok)
- `PartMapper.java` — Class: PartMapper (~257 tok)
- `PartQuantityMapper.java` — Class: PartQuantityMapper (~186 tok)
- `PreventiveMaintenanceMapper.java` — Class: PreventiveMaintenanceMapper (~1787 tok)
- `PurchaseOrderCategoryMapper.java` — Class: PurchaseOrderCategoryMapper (~191 tok)
- `PurchaseOrderMapper.java` — Class: PurchaseOrderMapper (~167 tok)
- `ReadingMapper.java` — Class: ReadingMapper (~122 tok)
- `RelationMapper.java` — Class: RelationMapper (~137 tok)
- `RequestMapper.java` — Class: RequestMapper (~225 tok)
- `RequestPortalMapper.java` — Class: RequestPortalMapper (~527 tok)
- `RoleMapper.java` — Class: RoleMapper (~114 tok)
- `ScheduleMapper.java` — Class: ScheduleMapper (~124 tok)
- `ShiftConfigurationMapper.java` — Class: ShiftConfigurationMapper (~214 tok)
- `SubscriptionMapper.java` — Class: SubscriptionMapper (~134 tok)
- `SubscriptionPlanMapper.java` — Class: SubscriptionPlanMapper (~145 tok)
- `SuperAccountRelationMapper.java` — Class: SuperAccountRelationMapper (~208 tok)
- `TaskBaseMapper.java` — Class: TaskBaseMapper (~159 tok)
- `TaskMapper.java` — Class: TaskMapper (~150 tok)
- `TaskOptionMapper.java` — Class: TaskOptionMapper (~156 tok)
- `TeamMapper.java` — Class: TeamMapper (~166 tok)
- `TimeCategoryMapper.java` — Class: TimeCategoryMapper (~131 tok)
- `UiConfigurationMapper.java` — Class: UiConfigurationMapper (~118 tok)
- `UserMapper.java` — UserMapper: toResponseDtoWithShift (~816 tok)
- `VendorMapper.java` — Class: VendorMapper (~201 tok)
- `WebhookEndpointMapper.java` — Class: WebhookEndpointMapper (~215 tok)
- `WorkflowActionMapper.java` — Class: WorkflowActionMapper (~266 tok)
- `WorkflowConditionMapper.java` — Class: WorkflowConditionMapper (~277 tok)
- `WorkflowMapper.java` — Class: WorkflowMapper (~169 tok)
- `WorkOrderCategoryMapper.java` — Class: WorkOrderCategoryMapper (~168 tok)
- `WorkOrderHistoryMapper.java` — Class: WorkOrderHistoryMapper (~107 tok)
- `WorkOrderMapper.java` — Class: WorkOrderMapper (~379 tok)
- `WorkOrderMeterTriggerMapper.java` — Class: WorkOrderMeterTriggerMapper (~286 tok)

## api/src/main/java/com/grash/model/

- `AdditionalCost.java` — Entity: AdditionalCost (~417 tok)
- `ApiKey.java` — Entity: ApiKey (~266 tok)

## api/src/main/java/com/grash/model/abstracts/

- `Audit.java` — Class: Audit (~224 tok)
- `BasicInfos.java` — Class: public (~114 tok)

## api/src/main/java/com/grash/service/ *(manual, partial)*

- `AzureBlobService.java` — Azure Blob backend, `STORAGE_TYPE=azure`. Managed identity signing user delegation SAS by default, shared key as fallback. Caches the delegation key (12h TTL) because FileMapper signs every file of every listing. Deliberately does not check blob existence before signing (~1850 tok)
- `GCPService.java` — Google Cloud Storage backend. Unlike the other two it checks blob existence before signing, costing a round trip per file (~1200 tok)
- `LicenseService.java` — AGPLv3 build: `getLicensingState()` returns a valid plan with every entitlement and `hasEntitlement()` returns true unconditionally. Single chokepoint for all feature gates and usage caps. Zero upstream churn (~900 tok)
- `MinioService.java` — S3-compatible backend. NB: builds its client on `PUBLIC_MINIO_ENDPOINT`, not `MINIO_ENDPOINT`; the latter is only an HTTP proxy target when the public endpoint is localhost. No-ops if any `MINIO_*` value is blank (~1600 tok)
- `StorageService.java` — Interface all storage backends implement: upload (MultipartFile and byte[]), download, generateSignedUrl. `uploadAndSign` is the default combo used by exports (~330 tok)

## infra/ *(manual)*

- `README.md` — Layout, blast radius, prerequisites, bootstrap procedure, vault seeding, the four role assignments and why user-assigned identity (~1750 tok)

## infra/bootstrap/ *(manual)*

- `main.tf` — One-time: `enkmtfstate001` state storage account + `tfstate` container, GRS with versioning. Keeps its own state locally until migrated into the container it creates (~450 tok)

## infra/envs/prod/ *(manual)*

- `backend.tf` — azurerm remote state, key `cmms/prod.tfstate`, AzureAD auth (~110 tok)
- `main.tf` — P1v3 plan, `atlasprod` database and user, image tag `prod`. Key Vault purge protection on (~520 tok)

## infra/envs/test/ *(manual)*

- `backend.tf` — azurerm remote state, key `cmms/test.tfstate`, AzureAD auth (~110 tok)
- `main.tf` — B2 plan, `atlastest` database and user, image tag `test`, spring profile `test`, mail disabled (~520 tok)

## infra/modules/cmms/ *(manual)*

- `main.tf` — The whole environment: user-assigned identity, App Service Plan, storage account + `atlas-files` container, Key Vault (RBAC, empty), Linux web app with VNet integration and all app settings, four role assignments, diagnostic setting. App settings hold literal `@Microsoft.KeyVault(...)` strings so no secret enters state (~2600 tok)
- `outputs.tf` — web_app_name, default_hostname, principal_id, key_vault_name, storage_account_name, image (~230 tok)
- `variables.tf` — Inputs. Notable: `db_host` is a private-endpoint IP not a name; `vnet_integration_subnet_id` is created out of band; `public_url` is also baked into the SPA at image build time (~1300 tok)
