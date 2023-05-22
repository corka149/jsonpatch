%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib", "test"]
      },
      checks: [
        {Credo.Check.Refactor.RedundantWithClauseResult, false},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
        {Credo.Check.Design.AliasUsage, false}
      ]
    }
  ]
}
