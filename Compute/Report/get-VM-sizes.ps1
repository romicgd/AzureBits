get-Azurermvm | select -expandproperty HardwareProfile  | group -property vmsize | select count, name | sort name
