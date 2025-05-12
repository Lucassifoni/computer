defmodule Computer.Graph do
  def graph(computer) do
    do_graph(computer.private)
  end

  def do_graph(%{names: names, depended_ons: don, depended_bys: dby}) do
    mermaid_graph = do_graph(%{names: names, depended_ons: don, depended_bys: dby}, :mermaid)
    dot_graph = do_graph(%{names: names, depended_ons: don, depended_bys: dby}, :dot)
    %{mermaid: mermaid_graph, dot: dot_graph}
  end

  def do_graph(%{names: names, depended_ons: don, depended_bys: _dby}, :mermaid) do
    edges =
      for {to, froms} <- don, from <- froms do
        "#{from} --> #{to}"
      end

    nodes =
      for {name, type} <- names do
        node_style = if type == :input, do: "[#{name}]", else: "((#{name}))"
        "#{name}#{node_style}"
      end

    (["graph TD"] ++ nodes ++ edges) |> Enum.join("\n")
  end

  def do_graph(%{names: names, depended_ons: don, depended_bys: _dby}, :dot) do
    edges =
      for {to, froms} <- don, from <- froms do
        "  \"#{from}\" -> \"#{to}\";"
      end

    nodes =
      for {name, type} <- names do
        shape = if type == :input, do: "box", else: "ellipse"
        "  \"#{name}\" [shape=#{shape}];"
      end

    (["digraph G {"] ++ nodes ++ edges ++ ["}"]) |> Enum.join("\n")
  end
end
