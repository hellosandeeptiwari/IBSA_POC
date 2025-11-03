CREATE TABLE [web].[SOpsAccountAddress] (
    [SOpsAccountAddressId] INT          IDENTITY (1, 1) NOT NULL,
    [SOpsAccountId]        INT          NOT NULL,
    [SOpsAddressId]        INT          NOT NULL,
    [Status]               NVARCHAR (4) NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsAccountAddressId] ASC),
    CONSTRAINT [FK_SOpsAccountAddress_SOpsAccountId] FOREIGN KEY ([SOpsAccountId]) REFERENCES [web].[SOpsAccount] ([SOpsAccountId]),
    CONSTRAINT [FK_SOpsAccountAddress_SOpsAddressId] FOREIGN KEY ([SOpsAddressId]) REFERENCES [web].[SOpsAddress] ([SOpsAddressId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountAddress_SOpsAccountAddressId]
    ON [web].[SOpsAccountAddress]([SOpsAccountAddressId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountAddress_SOpsAccountId]
    ON [web].[SOpsAccountAddress]([SOpsAccountId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountAddress_SOpsAddressId]
    ON [web].[SOpsAccountAddress]([SOpsAddressId] ASC);

