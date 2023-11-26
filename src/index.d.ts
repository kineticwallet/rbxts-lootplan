type LootplanType = "Multi" | "MultiLootplan" | "Single" | "SingleLootplan";
type LootItem = {
	Chance: number;
	Name: string;
};

declare class SingleLootplan {
	private Randomizer: Random;
	private Loot: Record<string, LootItem>;
	private LootList: Record<number, LootItem>;
	private LootCount: number;
	private TotalChance: number;
	private _updateLootList(): void;
	public AddLoot(chance: number, name: string): LootItem | undefined;
	public AddLootInBulk(bulkLoot: Record<string, number>): Record<string, number>;
	public GetLootChance(name: string): number | undefined;
	public GetTrueLootChance(name: string): number | undefined;
	public RemoveLoot(name: string): boolean;
	public ChangeLootChance(newChance: number, name: string): LuaTuple<[boolean, LootItem | undefined]>;
	public GetRandomLoot(luckMultiplier?: number): LootItem | undefined;
	public constructor(lootplanSeed?: number);
}
declare class MultiLootplan {
	private Randomizer: Random;
	private Loot: Record<string, number>;
	public constructor(lootplanSeed?: number);
	public AddLoot(chance: number, name: string): LootItem | undefined;
	public AddLootInBulk(bulkLoot: Record<string, number>): Record<string, number>;
	public GetLootChance(name: string): number | undefined;
	public RemoveLoot(name: string): boolean;
	public ChangeLootChance(newChance: number, name: string): LuaTuple<[boolean, LootItem | undefined]>;
	public GetRandomLoot(amount?: number, luckMultiplier?: number): Record<number, LootItem>;
}
export default function createLootplan(
	lootplanType: LootplanType,
	lootplanSeed?: number,
): MultiLootplan | SingleLootplan;
