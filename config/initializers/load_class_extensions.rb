require 'rubygems'


MAPPING_TABLE = {
    'ἀ' => 'α', 'ά' => 'α',  'ἁ' => 'α', 'ἂ' => 'α', 'ἃ' => 'α', 'ἄ' => 'α', 'ἅ' => 'α', 'ἆ' => 'α','ἇ' => 'α','ὰ' => 'α','ά' => 'α','ᾀ' => 'α','ᾁ' => 'α','ᾂ' => 'α','ᾃ' => 'α','ᾄ' => 'α','ᾅ' => 'α','ᾆ' => 'α','ᾇ' => 'α','ᾰ' => 'α','ᾱ' => 'α','ᾲ' => 'α','ᾳ' => 'α','ᾴ' => 'α','ᾶ' => 'α','ᾷ' => 'α',
    'Ἀ' => 'α','Ἁ'=> 'α','Ἂ'=> 'α','Ἃ'=> 'α','Ἄ'=> 'α','Ἅ'=> 'α','Ἆ'=> 'α','Ἇ'=> 'α','ᾈ'=> 'α','ᾉ'=> 'α','ᾊ'=> 'α','ᾋ'=> 'α','ᾌ'=> 'α','ᾍ'=> 'α','ᾎ'=> 'α','ᾏ'=> 'α','Ᾰ'=> 'α','Ᾱ'=> 'α','Ὰ'=> 'α','Ά'=> 'α','ᾼ'=> 'α',
    'ἐ' => 'ε', 'ἑ' => 'ε', 'ἒ' => 'ε', 'ἓ' => 'ε', 'ἔ' => 'ε', 'ἕ' => 'ε', 'ὲ' => 'ε','έ' => 'ε',  'Ἐ' => 'ε',  'Ἑ' => 'ε',  'Ἒ' => 'ε',  'Ἓ' => 'ε',  'Ἔ' => 'ε',  'Ἕ' => 'ε','Ὲ' => 'ε','Έ' => 'ε',
    'ἠ' => 'η','ἡ' => 'η','ἢ' => 'η','ἣ' => 'η','ἤ' => 'η','ἥ' => 'η','ἦ' => 'η', 'ἧ' => 'η',  'ὴ' => 'η', 'ή' => 'η', 'ᾐ' => 'η', 'ᾑ' => 'η', 'ᾒ' => 'η', 'ᾓ' => 'η', 'ᾔ' => 'η', 'ᾕ' => 'η', 'ᾖ' => 'η', 'ᾗ' => 'η', 'ῂ' => 'η', 'ῃ' => 'η', 'ῄ' => 'η', 'ῆ' => 'η', 'ῇ' => 'η',
    'Ἠ' => 'η', 'Ἡ' => 'η', 'Ἢ' => 'η', 'Ἣ' => 'η', 'Ἤ' => 'η', 'Ἥ' => 'η', 'Ἦ' => 'η', 'Ἧ' => 'η', 'ᾘ' => 'η','ᾙ' => 'η','ᾚ' => 'η','ᾛ' => 'η','ᾜ' => 'η','ᾝ' => 'η','ᾞ' => 'η','ᾟ' => 'η','Ὴ' => 'η','Ή' => 'η','ῌ' => 'η',
    'ἰ' => 'ι','ἱ' => 'ι','ἲ' => 'ι','ἳ' => 'ι','ἴ' => 'ι','ἵ' => 'ι','ἶ' => 'ι','ἷ' => 'ι', 'ὶ' => 'ι','ί' => 'ι','ῐ' => 'ι','ῑ' => 'ι','ῒ' => 'ι','ΐ' => 'ι','ῖ' => 'ι','ῗ' => 'ι',
    'Ἰ' => 'ι','Ἱ' => 'ι','Ἲ' => 'ι','Ἳ' => 'ι','Ἴ' => 'ι','Ἵ' => 'ι','Ἷ' => 'ι','Ἶ' => 'ι','Ῐ' => 'ι','Ῑ' => 'ι','Ὶ' => 'ι','Ί' => 'ι',
    'ὀ' => 'ο', 'ὁ' => 'ο', 'ὂ' => 'ο', 'ὃ' => 'ο', 'ὄ' => 'ο', 'ὅ' => 'ο','ὸ' => 'ο','ό' => 'ο',  'Ὀ' => 'ο', 'Ὁ' => 'ο', 'Ὂ' => 'ο', 'Ὃ' => 'ο', 'Ὄ' => 'ο', 'Ὅ' => 'ο','Ὸ' => 'ο','Ό' => 'ο',
    'ὐ' => 'υ','ὑ' => 'υ','ὒ' => 'υ','ὓ' => 'υ','ὔ' => 'υ','ὕ' => 'υ','ὖ' => 'υ','ὗ' => 'υ','ὺ' => 'υ', 'ύ' => 'υ', 'ῠ' => 'υ', 'ῡ' => 'υ', 'ῢ' => 'υ', 'ΰ' => 'υ', 'ῦ' => 'υ',  'Ὑ' => 'υ', 'Ὓ' => 'υ', 'Ὕ' => 'υ', 'Ὗ' => 'υ','Ῠ' => 'υ','Ῡ' => 'υ','Ὺ' => 'υ','Ύ' => 'υ',
    'ὠ' => 'ω', 'ὡ' => 'ω', 'ὢ' => 'ω', 'ὣ' => 'ω', 'ὤ' => 'ω', 'ὥ' => 'ω', 'ὦ' => 'ω', 'ὧ' => 'ω', 'ὼ' => 'ω', 'ώ' => 'ω', 'ᾠ' => 'ω', 'ᾡ' => 'ω', 'ᾢ' => 'ω', 'ᾣ' => 'ω', 'ᾤ' => 'ω', 'ᾥ' => 'ω', 'ᾦ' => 'ω', 'ᾧ' => 'ω', 'ῲ' => 'ω', 'ῳ' => 'ω', 'ῴ' => 'ω', 'ῶ' => 'ω', 'ῷ' => 'ω',
    'Ὠ' => 'ω', 'Ὡ' => 'ω', 'Ὢ' => 'ω', 'Ὣ' => 'ω', 'Ὤ' => 'ω', 'Ὥ' => 'ω', 'Ὦ' => 'ω', 'Ὧ' => 'ω','ᾨ' => 'ω','ᾩ' => 'ω','ᾪ' => 'ω','ᾫ' => 'ω','ᾬ' => 'ω','ᾭ' => 'ω','ᾮ' => 'ω','ᾯ' => 'ω','ῼ' => 'ω','Ὼ' => 'ω','Ώ' => 'ω',
    'ῤ' => 'ρ','ῥ' => 'ρ','Ῥ' => 'ρ', 'Β' =>  'β'  ,'Γ' => 'γ' ,'Ζ' => 'ζ' ,'Θ' => 'θ'   ,'Κ' => 'κ'  ,'Λ' => 'λ',  'Μ' => 'μ' ,'Π' => 'π'  ,'Σ' =>  'σ',  'ς'=> 'σ' ,'Τ' =>'τ'  ,'Φ' =>'φ' , 'Χ'=> 'χ'  ,'Ψ' =>'ψ'
}
class String
  # Converts the Greek Unicode characters contained in the string
  # to latin ones (aka greeklish) and returns self.
  # For unobstructive conversion call the non-bang method 'greeklish'
  #
  # example:
  #   puts 'αβγδεζηθικλμνξοπρστυφχψω άέήίϊΐόύ ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ ABCDEFGHIJKLMNOPQRSTUVXYZ'.greeklish
  # returns:
  #   avgdezhthiklmnksoprstyfxpsw aehiiioy AVGDEZHTHIKLMNKSOPRSTYFXPSW ABCDEFGHIJKLMNOPQRSTUVXYZ
  def accented
    for i in 0...self.chars.length
      char = self.chars[i]
      if MAPPING_TABLE[char.to_s]
        return true
      end
    end
    return false
  end

  def deaccent!


    for i in 0...self.chars.length
      char = self.chars[i]
      self[i] = MAPPING_TABLE[char.to_s] ? MAPPING_TABLE[char] : char
    end

    self
  end

  # Returns a new string which is converted from Greek Unicode characters
  # to latin ones (aka greeklish)
  def deaccent
    self.dup.deaccent!
  end
end