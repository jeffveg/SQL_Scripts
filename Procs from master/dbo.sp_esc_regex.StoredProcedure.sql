/****** Object:  StoredProcedure [dbo].[sp_esc_regex]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[sp_esc_regex]
	@stringToEscape VARCHAR(MAX)
as

select 'Find' 'X', replace(replace(replace(replace(replace(replace(replace(replace(string_escape(@stringToEscape,'json'),'(','\('),')','\)'),'.','\.'),'[','\['),']','\]'),'+','\+'),'*','\*'),'?','\?') 'String'
union
select 'Replace' 'X', string_escape(@stringToEscape,'json')
GO
