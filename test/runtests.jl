using TableTraitsUtils
using Base.Test

@testset "TableTraitsUtils" begin

columns = (Int[1,2,3], Float64[1.,2.,3.], String["John", "Sally", "Drew"])
names = [:children, :age, :name]

it = TableTraitsUtils.create_tableiterator(columns, names)

columns2, names2 = TableTraitsUtils.create_columns_from_iterabletable(it)

@test columns[1] == columns2[1]
@test columns[2] == columns2[2]
@test columns[3] == columns2[3]
@test names == names2

end
