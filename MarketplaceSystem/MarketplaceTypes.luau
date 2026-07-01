export type Listing = {
	Id: string,
	SellerId: number,
	ItemId: number,
	Price: number,
	CreatedTime: number,
}

export type TransactionResult = {
	Success: boolean,
	Message: string?,
}

return nil