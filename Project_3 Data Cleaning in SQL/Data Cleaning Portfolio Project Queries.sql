/*
Data Cleaning in SQL for Nashville Housing Dataset
*/

/* Initial Data Check */
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

-- Preview Date Conversion
SELECT SaleDate AS OriginalSaleDate, CONVERT(Date, SaleDate) AS ConvertedSaleDate
FROM PortfolioProject.dbo.NashvilleHousing;

-- Update SaleDate with Converted Date Format
UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);

-- If the update doesn’t apply correctly, add a new column and populate
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

--------------------------------------------------------------------------------------------------------------------------

-- Populate Missing Property Address Data

-- Preview missing PropertyAddress data for records sharing the same ParcelID
SELECT a.ParcelID, a.PropertyAddress AS Address_A, b.PropertyAddress AS Address_B, ISNULL(a.PropertyAddress, b.PropertyAddress) AS UpdatedAddress
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- Update PropertyAddress where it is NULL
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

--------------------------------------------------------------------------------------------------------------------------

-- Split Property Address into Individual Columns: Address, City, and State

-- Extract Address and City from PropertyAddress
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255),
    PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Preview OwnerAddress components
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM PortfolioProject.dbo.NashvilleHousing;

-- Add columns for OwnerAddress breakdown
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

--------------------------------------------------------------------------------------------------------------------------

-- Update SoldAsVacant Column: Change Y/N to Yes/No

-- Check Distinct Values in SoldAsVacant
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Update Y/N to Yes/No
UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
                    WHEN SoldAsVacant = 'Y' THEN 'Yes'
                    WHEN SoldAsVacant = 'N' THEN 'No'
                    ELSE SoldAsVacant
                  END;

--------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicate Records

WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID) AS row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Remove duplicates from the main table
DELETE FROM PortfolioProject.dbo.NashvilleHousing
WHERE UniqueID IN (
    SELECT UniqueID FROM RowNumCTE WHERE row_num > 1
);

--------------------------------------------------------------------------------------------------------------------------

-- Drop Unused Columns

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
