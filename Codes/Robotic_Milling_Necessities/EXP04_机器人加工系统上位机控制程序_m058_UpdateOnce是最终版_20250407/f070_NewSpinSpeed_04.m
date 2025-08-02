% f070_NewSpinSpeed_04: 计算新的主轴转速
function newSpin = f070_NewSpinSpeed_04(fc, n)
    % 计算k（k是向下取整的结果）
    k = floor(fc * 60 / n);
    
    % 根据k计算新的主轴转速n_new
    newSpin = 60 * fc / k;
end
