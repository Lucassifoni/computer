defmodule ComputerGraphTest do
  use ExUnit.Case
  alias Computer.Graph

  test "graph/1, roc calculator" do
    computer = Computer.Samples.RocCalculator.sample()

    result = Graph.graph(computer)

    assert Map.has_key?(result, :mermaid)
    assert Map.has_key?(result, :dot)

    # Test mermaid format
    assert result.mermaid =~ "graph TD"
    assert result.mermaid =~ "r[r]"
    assert result.mermaid =~ "s[s]"
    assert result.mermaid =~ "b[b]"
    assert result.mermaid =~ "curve[curve]"
    assert result.mermaid =~ "roc((roc))"
    assert result.mermaid =~ "r --> roc"
    assert result.mermaid =~ "s --> roc"
    assert result.mermaid =~ "b --> roc"
    assert result.mermaid =~ "curve --> roc"

    # Test dot format
    assert result.dot =~ "digraph G {"
    assert result.dot =~ "\"r\" [shape=box];"
    assert result.dot =~ "\"s\" [shape=box];"
    assert result.dot =~ "\"b\" [shape=box];"
    assert result.dot =~ "\"curve\" [shape=box];"
    assert result.dot =~ "\"roc\" [shape=ellipse];"
    assert result.dot =~ "\"r\" -> \"roc\";"
    assert result.dot =~ "\"s\" -> \"roc\";"
    assert result.dot =~ "\"b\" -> \"roc\";"
    assert result.dot =~ "\"curve\" -> \"roc\";"
  end

  test "graph/1, mpcc calculator" do
    computer = Computer.Samples.MpccCalc.sample()

    result = Graph.graph(computer)

    assert Map.has_key?(result, :mermaid)
    assert Map.has_key?(result, :dot)

    # Test mermaid format
    assert result.mermaid =~ "graph TD"
    assert result.mermaid =~ "d[d]"
    assert result.mermaid =~ "f[f]"
    assert result.mermaid =~ "ratio((ratio))"
    assert result.mermaid =~ "correction((correction))"
    assert result.mermaid =~ "undercorrection((undercorrection))"
    assert result.mermaid =~ "target((target))"
    assert result.mermaid =~ "d --> ratio"
    assert result.mermaid =~ "f --> ratio"
    assert result.mermaid =~ "d --> correction"
    assert result.mermaid =~ "ratio --> correction"
    assert result.mermaid =~ "ratio --> undercorrection"
    assert result.mermaid =~ "correction --> target"
    assert result.mermaid =~ "undercorrection --> target"

    # Test dot format
    assert result.dot =~ "digraph G {"
    assert result.dot =~ "\"d\" [shape=box];"
    assert result.dot =~ "\"f\" [shape=box];"
    assert result.dot =~ "\"ratio\" [shape=ellipse];"
    assert result.dot =~ "\"correction\" [shape=ellipse];"
    assert result.dot =~ "\"undercorrection\" [shape=ellipse];"
    assert result.dot =~ "\"target\" [shape=ellipse];"
    assert result.dot =~ "\"d\" -> \"ratio\";"
    assert result.dot =~ "\"f\" -> \"ratio\";"
    assert result.dot =~ "\"d\" -> \"correction\";"
    assert result.dot =~ "\"ratio\" -> \"correction\";"
    assert result.dot =~ "\"ratio\" -> \"undercorrection\";"
    assert result.dot =~ "\"correction\" -> \"target\";"
    assert result.dot =~ "\"undercorrection\" -> \"target\";"
  end
end
