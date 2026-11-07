CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);


DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
        IF NOT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'ordering') THEN
            CREATE SCHEMA ordering;
        END IF;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE SEQUENCE ordering.buyerseq START WITH 1 INCREMENT BY 10 NO CYCLE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE SEQUENCE ordering.orderitemseq START WITH 1 INCREMENT BY 10 NO CYCLE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE SEQUENCE ordering.orderseq START WITH 1 INCREMENT BY 10 NO CYCLE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE SEQUENCE ordering.paymentseq START WITH 1 INCREMENT BY 10 NO CYCLE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE TABLE ordering.buyers (
        "Id" integer NOT NULL,
        "IdentityGuid" character varying(200) NOT NULL,
        "Name" text,
        CONSTRAINT "PK_buyers" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE TABLE ordering.cardtypes (
        "Id" integer NOT NULL,
        "Name" character varying(200) NOT NULL,
        CONSTRAINT "PK_cardtypes" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE TABLE ordering."IntegrationEventLog" (
        "EventId" uuid NOT NULL,
        "EventTypeName" text NOT NULL,
        "State" integer NOT NULL,
        "TimesSent" integer NOT NULL,
        "CreationTime" timestamp with time zone NOT NULL,
        "Content" text NOT NULL,
        "TransactionId" uuid NOT NULL,
        CONSTRAINT "PK_IntegrationEventLog" PRIMARY KEY ("EventId")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE TABLE ordering.requests (
        "Id" uuid NOT NULL,
        "Name" text NOT NULL,
        "Time" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_requests" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE TABLE ordering.paymentmethods (
        "Id" integer NOT NULL,
        "CardTypeId" integer NOT NULL,
        "BuyerId" integer NOT NULL,
        "Alias" character varying(200) NOT NULL,
        "CardHolderName" character varying(200) NOT NULL,
        "CardNumber" character varying(25) NOT NULL,
        "Expiration" timestamp with time zone NOT NULL,
        CONSTRAINT "PK_paymentmethods" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_paymentmethods_buyers_BuyerId" FOREIGN KEY ("BuyerId") REFERENCES ordering.buyers ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_paymentmethods_cardtypes_CardTypeId" FOREIGN KEY ("CardTypeId") REFERENCES ordering.cardtypes ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE TABLE ordering.orders (
        "Id" integer NOT NULL,
        "OrderDate" timestamp with time zone NOT NULL,
        "Address_Street" text,
        "Address_City" text,
        "Address_State" text,
        "Address_Country" text,
        "Address_ZipCode" text,
        "BuyerId" integer,
        "OrderStatus" character varying(30) NOT NULL,
        "Description" text,
        "PaymentMethodId" integer,
        CONSTRAINT "PK_orders" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_orders_buyers_BuyerId" FOREIGN KEY ("BuyerId") REFERENCES ordering.buyers ("Id"),
        CONSTRAINT "FK_orders_paymentmethods_PaymentMethodId" FOREIGN KEY ("PaymentMethodId") REFERENCES ordering.paymentmethods ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE TABLE ordering."orderItems" (
        "Id" integer NOT NULL,
        "ProductName" text NOT NULL,
        "PictureUrl" text,
        "UnitPrice" numeric NOT NULL,
        "Discount" numeric NOT NULL,
        "Units" integer NOT NULL,
        "ProductId" integer NOT NULL,
        "OrderId" integer NOT NULL,
        CONSTRAINT "PK_orderItems" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_orderItems_orders_OrderId" FOREIGN KEY ("OrderId") REFERENCES ordering.orders ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE UNIQUE INDEX "IX_buyers_IdentityGuid" ON ordering.buyers ("IdentityGuid");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE INDEX "IX_orderItems_OrderId" ON ordering."orderItems" ("OrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE INDEX "IX_orders_BuyerId" ON ordering.orders ("BuyerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE INDEX "IX_orders_PaymentMethodId" ON ordering.orders ("PaymentMethodId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE INDEX "IX_paymentmethods_BuyerId" ON ordering.paymentmethods ("BuyerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    CREATE INDEX "IX_paymentmethods_CardTypeId" ON ordering.paymentmethods ("CardTypeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20261107074958_Initial') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20261107074958_Initial', '10.0.12');
    END IF;
END $EF$;
