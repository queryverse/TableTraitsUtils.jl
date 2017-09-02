using TableTraitsUtils
using Base.Test

include("test_source_without_length.jl")

@testset "TableTraitsUtils" begin

columns = (Int[1,2,3], Float64[1.,2.,3.], String["John", "Sally", "Drew"])
names = [:children, :age, :name]

it = TableTraitsUtils.create_tableiterator(columns, names)

columns2, names2 = TableTraitsUtils.create_columns_from_iterabletable(it)

columns3, names3 = TableTraitsUtils.create_columns_from_iterabletable(it, :all)

columns23, names23 = TableTraitsUtils.create_columns_from_iterabletable(it, [2,3])

@test columns[1] == columns2[1] == columns3[1]
@test columns[2] == columns2[2] == columns3[2]
@test columns[3] == columns2[3] == columns3[3]
@test length(columns) == length(columns2) == length(columns3)
@test columns[2] == columns23[1]
@test columns[3] == columns23[2]
@test length(columns23) == 2

@test names == names2 == names3
@test names[2:3] == names23

it2 = TestSourceWithoutLength()

columns4, names4 = TableTraitsUtils.create_columns_from_iterabletable(it2)
@test columns4[1] == [1,2]
@test columns4[2] == [1.,2.]
@test names4 == [:a, :b]

columns5, names5 = TableTraitsUtils.create_columns_from_iterabletable(it2, :all)
@test columns5[1] == [1,2]
@test columns5[2] == [1.,2.]
@test names5 == [:a, :b]

columns6, names6 = TableTraitsUtils.create_columns_from_iterabletable(it2, [2])
@test columns6[1] == [1.,2.]
@test names6 == [:b]


end
